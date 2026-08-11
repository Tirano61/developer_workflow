import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_filters.dart';

sealed class DiscussionEvent {
  const DiscussionEvent();
}

class LoadDiscussionsEvent extends DiscussionEvent {
  const LoadDiscussionsEvent({this.filters = const DiscussionFilters()});

  final DiscussionFilters filters;
}

class LoadDiscussionEvent extends DiscussionEvent {
  const LoadDiscussionEvent(this.id);

  final String id;
}

class CreateDiscussionEvent extends DiscussionEvent {
  const CreateDiscussionEvent(this.discussion);

  final Discussion discussion;
}

class UpdateDiscussionEvent extends DiscussionEvent {
  const UpdateDiscussionEvent(this.discussion);

  final Discussion discussion;
}
