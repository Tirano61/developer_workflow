import '../../../../core/error/result.dart';
import '../entities/discussion.dart';
import '../entities/discussion_filters.dart';
import '../entities/discussion_page.dart';

abstract class DiscussionRepository {
  Future<Result<DiscussionPage>> getDiscussions({
    DiscussionFilters filters = const DiscussionFilters(),
  });

  Future<Result<Discussion>> getDiscussionById(String id);

  Future<Result<Discussion>> createDiscussion(Discussion discussion);

  Future<Result<Discussion>> updateDiscussion(Discussion discussion);
}
