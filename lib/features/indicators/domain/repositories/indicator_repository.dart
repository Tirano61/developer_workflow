import '../../../../core/error/result.dart';
import '../entities/indicator.dart';

abstract class IndicatorRepository {
  Future<Result<List<Indicator>>> getIndicators();

  Future<Result<Indicator>> getIndicatorById(String id);

  Future<Result<Indicator>> createIndicator(Indicator indicator);

  Future<Result<Indicator>> updateIndicator(Indicator indicator);
}
