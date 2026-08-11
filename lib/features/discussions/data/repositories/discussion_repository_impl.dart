import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/discussion_filters.dart';
import '../../domain/entities/discussion_page.dart';
import '../../domain/repositories/discussion_repository.dart';
import '../datasources/discussion_remote_data_source.dart';
import '../models/discussion_model.dart';

class DiscussionRepositoryImpl implements DiscussionRepository {
  DiscussionRepositoryImpl({
    required DiscussionRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final DiscussionRemoteDataSource _remoteDataSource;

  @override
  Future<Result<DiscussionPage>> getDiscussions({
    DiscussionFilters filters = const DiscussionFilters(),
  }) async {
    try {
      final pageModel = await _remoteDataSource.getDiscussions(
        filters: filters,
      );
      return Success<DiscussionPage>(pageModel.toEntity());
    } catch (error) {
      return FailureResult<DiscussionPage>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Discussion>> getDiscussionById(String id) async {
    try {
      final model = await _remoteDataSource.getDiscussionById(id);
      return Success<Discussion>(model.toEntity());
    } catch (error) {
      return FailureResult<Discussion>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Discussion>> createDiscussion(Discussion discussion) async {
    try {
      final model = DiscussionModel.fromEntity(discussion);
      final created = await _remoteDataSource.createDiscussion(model);
      return Success<Discussion>(created.toEntity());
    } catch (error) {
      return FailureResult<Discussion>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Discussion>> updateDiscussion(Discussion discussion) async {
    try {
      final model = DiscussionModel.fromEntity(discussion);
      final updated = await _remoteDataSource.updateDiscussion(model);
      return Success<Discussion>(updated.toEntity());
    } catch (error) {
      return FailureResult<Discussion>(mapExceptionToFailure(error));
    }
  }
}
