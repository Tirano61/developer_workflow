import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_filters.dart';
import '../../domain/entities/discussion_page.dart';

enum DiscussionStatus { initial, loading, success, error }

class DiscussionState {
  const DiscussionState({
    this.status = DiscussionStatus.initial,
    this.page = DiscussionPage.empty,
    this.filters = const DiscussionFilters(),
    this.selectedDiscussion,
    this.errorMessage = '',
  });

  final DiscussionStatus status;
  final DiscussionPage page;
  final DiscussionFilters filters;
  final Discussion? selectedDiscussion;
  final String errorMessage;

  List<Discussion> get discussions => page.data;

  DiscussionState copyWith({
    DiscussionStatus? status,
    DiscussionPage? page,
    DiscussionFilters? filters,
    Discussion? selectedDiscussion,
    bool clearSelectedDiscussion = false,
    String? errorMessage,
  }) {
    return DiscussionState(
      status: status ?? this.status,
      page: page ?? this.page,
      filters: filters ?? this.filters,
      selectedDiscussion: clearSelectedDiscussion
          ? null
          : selectedDiscussion ?? this.selectedDiscussion,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
