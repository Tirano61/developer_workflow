import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../data/datasources/firebase_messaging_data_source.dart';
import '../../domain/repositories/notification_device_repository.dart';
import '../../domain/usecases/register_device.dart';
import '../../domain/usecases/unregister_device.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc({
    required FirebaseMessagingDataSource messagingDataSource,
    required RegisterDevice registerDevice,
    required UnregisterDevice unregisterDevice,
  }) : _messagingDataSource = messagingDataSource,
       _registerDevice = registerDevice,
       _unregisterDevice = unregisterDevice,
       super(const NotificationState()) {
    on<InitializeNotificationsEvent>(_onInitializeNotifications);
    on<NotificationAuthStateChangedEvent>(_onAuthStateChanged);
    on<NotificationTokenRefreshedEvent>(_onTokenRefreshed);
    on<NotificationForegroundMessageReceivedEvent>(
      _onForegroundMessageReceived,
    );
    on<NotificationOpenedEvent>(_onNotificationOpened);
    on<NotificationNavigationHandledEvent>(_onNavigationHandled);
  }

  final FirebaseMessagingDataSource _messagingDataSource;
  final RegisterDevice _registerDevice;
  final UnregisterDevice _unregisterDevice;

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  Future<void> _onInitializeNotifications(
    InitializeNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.initialized) {
      return;
    }

    emit(
      state.copyWith(status: NotificationStatus.initializing, errorMessage: ''),
    );

    final pushSupported = _isAndroidPushSupported;
    if (!pushSupported) {
      emit(
        state.copyWith(
          status: NotificationStatus.ready,
          pushSupported: false,
          initialized: true,
          errorMessage: '',
        ),
      );
      return;
    }

    _tokenRefreshSubscription = _messagingDataSource.onTokenRefresh.listen((
      token,
    ) {
      add(NotificationTokenRefreshedEvent(token));
    });

    _foregroundMessageSubscription = _messagingDataSource.onMessage.listen((
      message,
    ) {
      if (kDebugMode) {
        debugPrint(
          'FCM onMessage received. data=${_normalizeData(message.data)}',
        );
      }

      add(
        NotificationForegroundMessageReceivedEvent(
          _normalizeData(message.data),
        ),
      );
    });

    _messageOpenedSubscription = _messagingDataSource.onMessageOpenedApp.listen((
      message,
    ) {
      if (kDebugMode) {
        debugPrint(
          'FCM onMessageOpenedApp received. data=${_normalizeData(message.data)}',
        );
      }

      add(
        NotificationOpenedEvent(
          data: _normalizeData(message.data),
          source: 'onMessageOpenedApp',
        ),
      );
    });

    try {
      final initialMessage = await _messagingDataSource.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          debugPrint(
            'FCM getInitialMessage received. data=${_normalizeData(initialMessage.data)}',
          );
        }

        add(
          NotificationOpenedEvent(
            data: _normalizeData(initialMessage.data),
            source: 'getInitialMessage',
          ),
        );
      }

      emit(
        state.copyWith(
          status: NotificationStatus.ready,
          pushSupported: true,
          initialized: true,
          errorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: NotificationStatus.error,
          pushSupported: true,
          initialized: true,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onAuthStateChanged(
    NotificationAuthStateChangedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final wasAuthenticated = state.isAuthenticated;

    emit(
      state.copyWith(isAuthenticated: event.isAuthenticated, errorMessage: ''),
    );

    if (!state.pushSupported || !state.initialized) {
      return;
    }

    if (event.isAuthenticated) {
      await _ensurePermissionAndToken(emit);
      final token = state.currentFcmToken?.trim();
      if (token != null && token.isNotEmpty) {
        await _registerTokenIfNeeded(token, emit);
      }

      final pendingDiscussionId = state.pendingDiscussionId?.trim();
      if (pendingDiscussionId != null && pendingDiscussionId.isNotEmpty) {
        emit(
          state.copyWith(
            openDiscussionId: pendingDiscussionId,
            clearPendingDiscussionId: true,
            navigationRequestVersion: state.navigationRequestVersion + 1,
          ),
        );
      }
      return;
    }

    if (wasAuthenticated) {
      await _unregisterCurrentTokenBestEffort(emit);
    }
  }

  Future<void> _onTokenRefreshed(
    NotificationTokenRefreshedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final token = event.token.trim();
    if (token.isEmpty) {
      return;
    }

    emit(state.copyWith(currentFcmToken: token, errorMessage: ''));

    if (!state.isAuthenticated) {
      return;
    }

    await _registerTokenIfNeeded(token, emit);
  }

  Future<void> _onForegroundMessageReceived(
    NotificationForegroundMessageReceivedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint('FCM foreground event handled. data=${event.data}');
    }

    final notificationType = event.data['type']?.trim() ?? '';
    emit(
      state.copyWith(lastNotificationType: notificationType, errorMessage: ''),
    );
  }

  Future<void> _onNotificationOpened(
    NotificationOpenedEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (kDebugMode) {
      debugPrint(
        'FCM open event handled. source=${event.source}, data=${event.data}',
      );
    }

    final discussionId = _readDiscussionId(event.data);
    if (discussionId == null) {
      return;
    }

    if (state.isAuthenticated) {
      emit(
        state.copyWith(
          openDiscussionId: discussionId,
          clearPendingDiscussionId: true,
          navigationRequestVersion: state.navigationRequestVersion + 1,
        ),
      );
      return;
    }

    emit(state.copyWith(pendingDiscussionId: discussionId));
  }

  Future<void> _onNavigationHandled(
    NotificationNavigationHandledEvent event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(clearOpenDiscussionId: true));
  }

  Future<void> _ensurePermissionAndToken(
    Emitter<NotificationState> emit,
  ) async {
    if (!state.permissionRequested) {
      try {
        final settings = await _messagingDataSource.requestPermission();
        if (kDebugMode) {
          debugPrint(
            'FCM PERMISSION: ${settings.authorizationStatus}',
          );
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('FCM requestPermission failed: $error');
        }
      }

      emit(state.copyWith(permissionRequested: true));
    }

    final existingToken = state.currentFcmToken?.trim();
    if (existingToken != null && existingToken.isNotEmpty) {
      return;
    }

    try {
      final token = await _messagingDataSource.getToken();
      if (kDebugMode) {
        debugPrint('FCM TOKEN ACTUAL: $token');
      }

      final normalizedToken = token?.trim();
      if (normalizedToken != null && normalizedToken.isNotEmpty) {
        emit(state.copyWith(currentFcmToken: normalizedToken));
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('FCM getToken failed: $error');
      }
    }
  }

  Future<void> _registerTokenIfNeeded(
    String token,
    Emitter<NotificationState> emit,
  ) async {
    final currentRegistered = state.lastRegisteredToken?.trim();
    if (currentRegistered == token) {
      return;
    }

    final result = await _registerDevice(
      RegisterDeviceParams(
        token: token,
        platform: NotificationDevicePlatform.android,
      ),
    );

    if (result is Success<void>) {
      emit(state.copyWith(lastRegisteredToken: token, errorMessage: ''));
      return;
    }

    if (result is FailureResult<void>) {
      emit(state.copyWith(errorMessage: result.failure.message));
    }
  }

  Future<void> _unregisterCurrentTokenBestEffort(
    Emitter<NotificationState> emit,
  ) async {
    final token = (state.currentFcmToken ?? state.lastRegisteredToken)?.trim();
    if (token == null || token.isEmpty) {
      emit(state.copyWith(clearLastRegisteredToken: true));
      return;
    }

    final result = await _unregisterDevice(
      UnregisterDeviceParams(token: token),
    );
    if (result is FailureResult<void> && kDebugMode) {
      debugPrint(
        'FCM unregister failed during logout: ${result.failure.message}',
      );
    }

    emit(state.copyWith(clearLastRegisteredToken: true));
  }

  String? _readDiscussionId(Map<String, String> data) {
    final value = data['discussionId']?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  Map<String, String> _normalizeData(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, value.toString()));
  }

  bool get _isAndroidPushSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Future<void> close() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _messageOpenedSubscription?.cancel();
    return super.close();
  }
}
