import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_filters.dart';
import '../models/discussion_model.dart';

abstract class DiscussionRemoteDataSource {
  Future<DiscussionPageModel> getDiscussions({
    DiscussionFilters filters = const DiscussionFilters(),
  });

  Future<DiscussionModel> getDiscussionById(String id);

  Future<DiscussionModel> createDiscussion(DiscussionModel discussion);

  Future<DiscussionModel> updateDiscussion(DiscussionModel discussion);
}

class DiscussionRemoteDataSourceImpl implements DiscussionRemoteDataSource {
  DiscussionRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<DiscussionPageModel> getDiscussions({
    DiscussionFilters filters = const DiscussionFilters(),
  }) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.discussions,
      queryParameters: _buildQueryParameters(filters),
    );

    return DiscussionPageModel.fromPayload(response.data);
  }

  @override
  Future<DiscussionModel> getDiscussionById(String id) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.discussionById(Uri.encodeComponent(id)),
    );

    return _parseSingleDiscussion(response.data);
  }

  @override
  Future<DiscussionModel> createDiscussion(DiscussionModel discussion) async {
    final payload = discussion.toJson()..remove('id');

    final response = await _restClient.post<Object?>(
      ApiEndpoints.discussions,
      body: payload,
    );

    return _parseSingleDiscussion(response.data);
  }

  @override
  Future<DiscussionModel> updateDiscussion(DiscussionModel discussion) async {
    final id = discussion.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'A discussion id is required to update the discussion.',
      );
    }

    final payload = discussion.toJson()..remove('id');

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.discussionById(Uri.encodeComponent(id)),
      body: payload,
    );

    return _parseSingleDiscussion(response.data);
  }

  DiscussionModel _parseSingleDiscussion(Object? payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return DiscussionModel.fromJson(data);
      }

      final discussion = payload['discussion'];
      if (discussion is Map<String, dynamic>) {
        return DiscussionModel.fromJson(discussion);
      }

      return DiscussionModel.fromJson(payload);
    }

    throw const DataParsingException(
      'Unexpected payload format for discussion item response.',
    );
  }

  QueryParams _buildQueryParameters(DiscussionFilters filters) {
    final params = <String, dynamic>{
      'page': filters.page,
      'limit': filters.limit,
    };

    if (filters.type != null && filters.type != DiscussionType.unknown) {
      params['type'] = filters.type!.apiValue;
    }

    if (filters.status != null &&
        filters.status != DiscussionRecordStatus.unknown) {
      params['status'] = filters.status!.apiValue;
    }

    final applicationIds = _normalizeIds(filters.applicationIds);
    if (applicationIds.isNotEmpty) {
      params['applicationIds'] = applicationIds.join(',');
    }

    final indicatorIds = _normalizeIds(filters.indicatorIds);
    if (indicatorIds.isNotEmpty) {
      params['indicatorIds'] = indicatorIds.join(',');
    }

    final tagIds = _normalizeIds(filters.tagIds);
    if (tagIds.isNotEmpty) {
      params['tagIds'] = tagIds.join(',');
    }

    final createdBy = filters.createdBy?.trim();
    if (createdBy != null && createdBy.isNotEmpty) {
      params['createdBy'] = createdBy;
    }

    if (filters.mine) {
      params['mine'] = true;
    }

    return params;
  }

  List<String> _normalizeIds(List<String> ids) {
    return ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
