import 'discussion.dart';

class DiscussionFilters {
  const DiscussionFilters({
    this.page = 1,
    this.limit = 20,
    this.type,
    this.status,
    this.applicationIds = const [],
    this.indicatorIds = const [],
    this.tagIds = const [],
    this.createdBy,
    this.mine = false,
  });

  final int page;
  final int limit;
  final DiscussionType? type;
  final DiscussionRecordStatus? status;
  final List<String> applicationIds;
  final List<String> indicatorIds;
  final List<String> tagIds;
  final String? createdBy;
  final bool mine;

  DiscussionFilters copyWith({
    int? page,
    int? limit,
    DiscussionType? type,
    bool clearType = false,
    DiscussionRecordStatus? status,
    bool clearStatus = false,
    List<String>? applicationIds,
    List<String>? indicatorIds,
    List<String>? tagIds,
    String? createdBy,
    bool clearCreatedBy = false,
    bool? mine,
  }) {
    return DiscussionFilters(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      type: clearType ? null : type ?? this.type,
      status: clearStatus ? null : status ?? this.status,
      applicationIds: applicationIds ?? this.applicationIds,
      indicatorIds: indicatorIds ?? this.indicatorIds,
      tagIds: tagIds ?? this.tagIds,
      createdBy: clearCreatedBy ? null : createdBy ?? this.createdBy,
      mine: mine ?? this.mine,
    );
  }
}
