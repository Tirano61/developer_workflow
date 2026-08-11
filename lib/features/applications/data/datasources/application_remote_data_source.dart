import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../models/application_model.dart';

abstract class ApplicationRemoteDataSource {
  Future<List<ApplicationModel>> getApplications();

  Future<ApplicationModel> getApplicationById(String id);

  Future<ApplicationModel> createApplication(ApplicationModel model);

  Future<ApplicationModel> updateApplication(ApplicationModel model);
}

class ApplicationRemoteDataSourceImpl implements ApplicationRemoteDataSource {
  ApplicationRemoteDataSourceImpl({required RestClient restClient})
      : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<List<ApplicationModel>> getApplications() async {
    final response = await _restClient.get<Object?>(ApiEndpoints.applications);
    final list = _extractList(response.data, key: 'applications');

    return list
        .map((item) => ApplicationModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<ApplicationModel> getApplicationById(String id) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.applicationById(Uri.encodeComponent(id)),
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return ApplicationModel.fromJson(map);
  }

  @override
  Future<ApplicationModel> createApplication(ApplicationModel model) async {
    final response = await _restClient.post<Object?>(
      ApiEndpoints.applications,
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return ApplicationModel.fromJson(map);
  }

  @override
  Future<ApplicationModel> updateApplication(ApplicationModel model) async {
    final id = model.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'Se requiere un id para actualizar una Application.',
      );
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.applicationById(Uri.encodeComponent(id)),
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'application');
    return ApplicationModel.fromJson(map);
  }

  List<dynamic> _extractList(Object? payload, {required String key}) {
    if (payload is List) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data;
      }

      final items = payload['items'];
      if (items is List) {
        return items;
      }

      final collection = payload[key];
      if (collection is List) {
        return collection;
      }
    }

    throw const DataParsingException(
      'Formato inesperado al obtener listado de Applications.',
    );
  }

  Map<String, dynamic> _extractEntityMap(
    Object? payload, {
    required String key,
  }) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }

      final entity = payload[key];
      if (entity is Map<String, dynamic>) {
        return entity;
      }

      return payload;
    }

    throw const DataParsingException(
      'Formato inesperado al obtener una Application.',
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de item en listado de Applications.',
    );
  }
}