import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/discussion_message.dart';
import '../../domain/entities/discussion_message_page.dart';
import '../../domain/usecases/create_discussion_message.dart' as create_uc;
import '../../domain/usecases/get_discussion_messages.dart' as get_uc;
import '../../domain/usecases/update_discussion_message.dart' as update_uc;
import 'discussion_message_event.dart';
import 'discussion_message_state.dart';

class DiscussionMessageBloc
    extends Bloc<DiscussionMessageEvent, DiscussionMessageState> {
  DiscussionMessageBloc({
    required get_uc.GetDiscussionMessages getDiscussionMessages,
    required create_uc.CreateDiscussionMessage createDiscussionMessage,
    required update_uc.UpdateDiscussionMessage updateDiscussionMessage,
  }) : _getDiscussionMessages = getDiscussionMessages,
       _createDiscussionMessage = createDiscussionMessage,
       _updateDiscussionMessage = updateDiscussionMessage,
       super(const DiscussionMessageState()) {
    on<LoadDiscussionMessagesEvent>(_onLoadDiscussionMessages);
    on<LoadMoreDiscussionMessagesEvent>(_onLoadMoreDiscussionMessages);
    on<CreateDiscussionMessageEvent>(_onCreateDiscussionMessage);
    on<UpdateDiscussionMessageEvent>(_onUpdateDiscussionMessage);
  }

  final get_uc.GetDiscussionMessages _getDiscussionMessages;
  final create_uc.CreateDiscussionMessage _createDiscussionMessage;
  final update_uc.UpdateDiscussionMessage _updateDiscussionMessage;

  Future<void> _onLoadDiscussionMessages(
    LoadDiscussionMessagesEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    final shouldReset =
        state.activeDiscussionId != event.discussionId || event.page == 1;

    emit(
      state.copyWith(
        status: DiscussionMessageStatus.loading,
        activeDiscussionId: event.discussionId,
        page: shouldReset
            ? DiscussionMessagePage.empty.copyWith(limit: event.limit)
            : state.page,
        errorMessage: '',
        isLoadingMore: false,
        isSending: false,
        isUpdating: false,
        clearUpdatingMessageId: true,
      ),
    );

    final result = await _getDiscussionMessages(
      get_uc.GetDiscussionMessagesParams(
        discussionId: event.discussionId,
        page: event.page,
        limit: event.limit,
        type: event.type,
      ),
    );

    if (result is Success<DiscussionMessagePage>) {
      final sortedData = _sortByBackendChronology(result.data.data);

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          activeDiscussionId: event.discussionId,
          page: result.data.copyWith(data: sortedData),
          errorMessage: '',
          isLoadingMore: false,
          isSending: false,
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessagePage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isLoadingMore: false,
          isSending: false,
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
    }
  }

  Future<void> _onLoadMoreDiscussionMessages(
    LoadMoreDiscussionMessagesEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    if (state.activeDiscussionId != event.discussionId ||
        state.status == DiscussionMessageStatus.loading ||
        state.isLoadingMore ||
        !state.page.hasNext) {
      return;
    }

    final nextPage = state.page.page + 1;

    emit(state.copyWith(isLoadingMore: true, errorMessage: ''));

    final result = await _getDiscussionMessages(
      get_uc.GetDiscussionMessagesParams(
        discussionId: event.discussionId,
        page: nextPage,
        limit: event.limit,
        type: event.type,
      ),
    );

    if (result is Success<DiscussionMessagePage>) {
      final merged = _mergeByIdAndSort(state.page.data, result.data.data);

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          page: result.data.copyWith(data: merged),
          errorMessage: '',
          isLoadingMore: false,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessagePage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isLoadingMore: false,
        ),
      );
    }
  }

  Future<void> _onCreateDiscussionMessage(
    CreateDiscussionMessageEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    final content = event.content.trim();
    if (content.isEmpty) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: 'El contenido del mensaje es obligatorio.',
          isSending: false,
        ),
      );
      return;
    }

    emit(state.copyWith(isSending: true, errorMessage: ''));

    final result = await _createDiscussionMessage(
      create_uc.CreateDiscussionMessageParams(
        discussionId: event.discussionId,
        content: content,
        type: event.type,
      ),
    );

    if (result is Success<DiscussionMessage>) {
      final created = result.data;
      final currentData = state.activeDiscussionId == event.discussionId
          ? state.page.data
          : const <DiscussionMessage>[];

      final alreadyExists = currentData.any((item) => item.id == created.id);
      final mergedData = _mergeByIdAndSort(currentData, [created]);

      final currentLimit = state.activeDiscussionId == event.discussionId
          ? state.page.limit
          : 50;
      final currentTotal = state.activeDiscussionId == event.discussionId
          ? state.page.total
          : 0;
      var mergedTotal = alreadyExists ? currentTotal : currentTotal + 1;
      if (mergedTotal < mergedData.length) {
        mergedTotal = mergedData.length;
      }

      final totalPages = mergedTotal == 0
          ? 0
          : (mergedTotal / currentLimit).ceil();

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          activeDiscussionId: event.discussionId,
          page: DiscussionMessagePage(
            data: mergedData,
            page: 1,
            limit: currentLimit,
            total: mergedTotal,
            totalPages: totalPages,
          ),
          errorMessage: '',
          isSending: false,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isSending: false,
        ),
      );
    }
  }

  Future<void> _onUpdateDiscussionMessage(
    UpdateDiscussionMessageEvent event,
    Emitter<DiscussionMessageState> emit,
  ) async {
    final content = event.content.trim();
    if (content.isEmpty) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: 'El contenido del mensaje es obligatorio.',
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isUpdating: true,
        updatingMessageId: event.messageId,
        errorMessage: '',
      ),
    );

    final result = await _updateDiscussionMessage(
      update_uc.UpdateDiscussionMessageParams(
        discussionId: event.discussionId,
        messageId: event.messageId,
        content: content,
      ),
    );

    if (result is Success<DiscussionMessage>) {
      final updated = result.data;
      final data = state.activeDiscussionId == event.discussionId
          ? _mergeByIdAndSort(state.page.data, [updated])
          : state.page.data;

      emit(
        state.copyWith(
          status: DiscussionMessageStatus.success,
          page: state.page.copyWith(data: data),
          errorMessage: '',
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionMessage>) {
      emit(
        state.copyWith(
          status: DiscussionMessageStatus.error,
          errorMessage: result.failure.message,
          isUpdating: false,
          clearUpdatingMessageId: true,
        ),
      );
    }
  }

  List<DiscussionMessage> _mergeByIdAndSort(
    List<DiscussionMessage> current,
    List<DiscussionMessage> incoming,
  ) {
    final mapById = <String, DiscussionMessage>{
      for (final message in current) message.id: message,
    };

    for (final message in incoming) {
      mapById[message.id] = message;
    }

    return _sortByBackendChronology(mapById.values);
  }

  List<DiscussionMessage> _sortByBackendChronology(
    Iterable<DiscussionMessage> source,
  ) {
    final list = List<DiscussionMessage>.from(source);
    list.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate != null && bDate != null) {
        final dateComparison = aDate.compareTo(bDate);
        if (dateComparison != 0) {
          return dateComparison;
        }
      } else if (aDate == null && bDate != null) {
        return -1;
      } else if (aDate != null && bDate == null) {
        return 1;
      }

      return a.id.compareTo(b.id);
    });

    return List<DiscussionMessage>.unmodifiable(list);
  }
}
