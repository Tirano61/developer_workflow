import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/indicator.dart';
import '../../domain/repositories/indicator_repository.dart';
import '../datasources/indicator_remote_data_source.dart';
import '../models/indicator_model.dart';

class IndicatorRepositoryImpl implements IndicatorRepository {
  IndicatorRepositoryImpl({required IndicatorRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  final IndicatorRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<Indicator>>> getIndicators() async {
    try {
      final models = await _remoteDataSource.getIndicators();
      final entities = models.map((model) => model.toEntity()).toList(growable: false);
      return Success<List<Indicator>>(entities);
    } catch (error) {
      return FailureResult<List<Indicator>>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Indicator>> getIndicatorById(String id) async {
    try {
      final model = await _remoteDataSource.getIndicatorById(id);
      return Success<Indicator>(model.toEntity());
    } catch (error) {
      return FailureResult<Indicator>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Indicator>> createIndicator(Indicator indicator) async {
    try {
      final model = IndicatorModel.fromEntity(indicator);
      final created = await _remoteDataSource.createIndicator(model);
      return Success<Indicator>(created.toEntity());
    } catch (error) {
      return FailureResult<Indicator>(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Indicator>> updateIndicator(Indicator indicator) async {
    try {
      final model = IndicatorModel.fromEntity(indicator);
      final updated = await _remoteDataSource.updateIndicator(model);
      return Success<Indicator>(updated.toEntity());
    } catch (error) {
      return FailureResult<Indicator>(mapExceptionToFailure(error));
    }
  }
}
