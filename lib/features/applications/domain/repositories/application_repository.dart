import '../../../../core/error/result.dart';
import '../entities/application.dart';

abstract class ApplicationRepository {
  Future<Result<List<Application>>> getApplications();

  Future<Result<Application>> getApplicationById(String id);

  Future<Result<Application>> createApplication(Application application);

  Future<Result<Application>> updateApplication(Application application);
}