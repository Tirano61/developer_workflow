import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../models/indicator_model.dart';

abstract class IndicatorRemoteDataSource {
  Future<List<IndicatorModel>> getIndicators();

  Future<IndicatorModel> getIndicatorById(String id);

  Future<IndicatorModel> createIndicator(IndicatorModel model);

  Future<IndicatorModel> updateIndicator(IndicatorModel model);
}

class IndicatorRemoteDataSourceImpl implements IndicatorRemoteDataSource {
  IndicatorRemoteDataSourceImpl({required RestClient restClient})
      : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<List<IndicatorModel>> getIndicators() async {
    final response = await _restClient.get<Object?>(ApiEndpoints.indicators);
    final list = _extractList(response.data, key: 'indicators');

    return list
        .map((item) => IndicatorModel.fromJson(_extractMap(item)))
        .toList(growable: false);
  }

  @override
  Future<IndicatorModel> getIndicatorById(String id) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.indicatorById(Uri.encodeComponent(id)),
    );
    final map = _extractEntityMap(response.data, key: 'indicator');
    return IndicatorModel.fromJson(map);
  }

  @override
  Future<IndicatorModel> createIndicator(IndicatorModel model) async {
    final response = await _restClient.post<Object?>(
      ApiEndpoints.indicators,
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'indicator');
    return IndicatorModel.fromJson(map);
  }

  @override
  Future<IndicatorModel> updateIndicator(IndicatorModel model) async {
    final id = model.id;
    if (id == null || id.trim().isEmpty) {
      throw const ValidationException(
        'Se requiere un id para actualizar un Indicator.',
      );
    }

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.indicatorById(Uri.encodeComponent(id)),
      body: model.toJson(),
    );
    final map = _extractEntityMap(response.data, key: 'indicator');
    return IndicatorModel.fromJson(map);
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
      'Formato inesperado al obtener listado de Indicators.',
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
      'Formato inesperado al obtener un Indicator.',
    );
  }

  Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    throw const DataParsingException(
      'Formato inesperado de item en listado de Indicators.',
    );
  }
}
