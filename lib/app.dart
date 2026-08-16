import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/discussions/presentation/pages/discussion_route_args.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
import 'features/notifications/presentation/bloc/notification_state.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<NotificationBloc>(
          create: (_) {
            final bloc = sl<NotificationBloc>();
            bloc.add(const InitializeNotificationsEvent());
            return bloc;
          },
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.infoMessage != current.infoMessage,
            listener: (context, state) {
              context.read<NotificationBloc>().add(
                NotificationAuthStateChangedEvent(
                  isAuthenticated: state.isAuthenticated,
                ),
              );

              final navigator = AppRouter.navigatorKey.currentState;
              final messenger = AppRouter.scaffoldMessengerKey.currentState;

              if (state.infoMessage.isNotEmpty) {
                messenger
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(state.infoMessage)));
              }

              if (state.status == AuthStatus.authenticated) {
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.home,
                  (route) => false,
                );
                return;
              }

              if (state.status == AuthStatus.unauthenticated) {
                navigator?.pushNamedAndRemoveUntil(
                  AppRoutes.login,
                  (route) => false,
                );
              }
            },
          ),
          BlocListener<NotificationBloc, NotificationState>(
            listenWhen: (previous, current) =>
                previous.navigationRequestVersion !=
                current.navigationRequestVersion,
            listener: (context, state) {
              final discussionId = state.openDiscussionId?.trim();
              if (discussionId == null || discussionId.isEmpty) {
                return;
              }

              final navigator = AppRouter.navigatorKey.currentState;
              navigator?.pushNamed(
                AppRoutes.discussionDetail,
                arguments: DiscussionDetailRouteArgs(
                  discussionId: discussionId,
                ),
              );

              context.read<NotificationBloc>().add(
                const NotificationNavigationHandledEvent(),
              );
            },
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.light,
          navigatorKey: AppRouter.navigatorKey,
          scaffoldMessengerKey: AppRouter.scaffoldMessengerKey,
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );
  }
}
