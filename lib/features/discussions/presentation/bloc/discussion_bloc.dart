import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_page.dart';
import '../../domain/usecases/create_discussion.dart';
import '../../domain/usecases/get_discussion.dart';
import '../../domain/usecases/get_discussions.dart';
import '../../domain/usecases/update_discussion.dart';
import 'discussion_event.dart';
import 'discussion_state.dart';

class DiscussionBloc extends Bloc<DiscussionEvent, DiscussionState> {
  DiscussionBloc({
    required GetDiscussions getDiscussions,
    required GetDiscussion getDiscussion,
    required CreateDiscussion createDiscussion,
    required UpdateDiscussion updateDiscussion,
  }) : _getDiscussions = getDiscussions,
       _getDiscussion = getDiscussion,
       _createDiscussion = createDiscussion,
       _updateDiscussion = updateDiscussion,
       super(const DiscussionState()) {
    on<LoadDiscussionsEvent>(_onLoadDiscussions);
    on<LoadDiscussionEvent>(_onLoadDiscussion);
    on<CreateDiscussionEvent>(_onCreateDiscussion);
    on<UpdateDiscussionEvent>(_onUpdateDiscussion);
  }

  final GetDiscussions _getDiscussions;
  final GetDiscussion _getDiscussion;
  final CreateDiscussion _createDiscussion;
  final UpdateDiscussion _updateDiscussion;

  Future<void> _onLoadDiscussions(
    LoadDiscussionsEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DiscussionStatus.loading,
        filters: event.filters,
        errorMessage: '',
      ),
    );

    final result = await _getDiscussions(filters: event.filters);

    if (result is Success<DiscussionPage>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          page: result.data,
          filters: event.filters,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<DiscussionPage>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadDiscussion(
    LoadDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(state.copyWith(status: DiscussionStatus.loading, errorMessage: ''));

    final result = await _getDiscussion(event.id);

    if (result is Success<Discussion>) {
      final selected = result.data;
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: selected,
          page: _mergeDiscussionIntoPage(state.page, selected),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Discussion>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCreateDiscussion(
    CreateDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(state.copyWith(status: DiscussionStatus.loading, errorMessage: ''));

    final result = await _createDiscussion(event.discussion);

    if (result is Success<Discussion>) {
      final created = result.data;
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: created,
          page: _mergeDiscussionIntoPage(state.page, created),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Discussion>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onUpdateDiscussion(
    UpdateDiscussionEvent event,
    Emitter<DiscussionState> emit,
  ) async {
    emit(state.copyWith(status: DiscussionStatus.loading, errorMessage: ''));

    final result = await _updateDiscussion(event.discussion);

    if (result is Success<Discussion>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: DiscussionStatus.success,
          selectedDiscussion: updated,
          page: _mergeDiscussionIntoPage(state.page, updated),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Discussion>) {
      emit(
        state.copyWith(
          status: DiscussionStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  DiscussionPage _mergeDiscussionIntoPage(
    DiscussionPage current,
    Discussion discussion,
  ) {
    final alreadyExists = _containsDiscussion(current.data, discussion);
    final mergedData = _upsertById(current.data, discussion);

    var mergedTotal = current.total;
    if (!alreadyExists) {
      mergedTotal = current.total > 0 ? current.total + 1 : mergedData.length;
    }

    if (mergedTotal < mergedData.length) {
      mergedTotal = mergedData.length;
    }

    final mergedTotalPages = mergedTotal == 0
        ? 0
        : current.limit > 0
        ? (mergedTotal / current.limit).ceil()
        : current.totalPages;

    return current.copyWith(
      data: mergedData,
      total: mergedTotal,
      totalPages: mergedTotalPages,
    );
  }

  bool _containsDiscussion(List<Discussion> current, Discussion discussion) {
    final discussionId = discussion.id;
    if (discussionId == null || discussionId.isEmpty) {
      return false;
    }

    return current.any((item) => item.id == discussionId);
  }

  List<Discussion> _upsertById(
    List<Discussion> current,
    Discussion discussion,
  ) {
    final next = List<Discussion>.from(current);
    final index = next.indexWhere(
      (item) =>
          item.id != null && discussion.id != null && item.id == discussion.id,
    );

    if (index >= 0) {
      next[index] = discussion;
      return List<Discussion>.unmodifiable(next);
    }

    next.insert(0, discussion);
    return List<Discussion>.unmodifiable(next);
  }
}
