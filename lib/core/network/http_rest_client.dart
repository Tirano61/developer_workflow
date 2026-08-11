import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../error/exceptions.dart';
import 'network_config.dart';
import 'rest_client.dart';

class HttpRestClient implements RestClient {
  HttpRestClient({
    required http.Client client,
    required NetworkConfig config,
  })  : _client = client,
        _config = config,
        _baseUri = Uri.parse(config.baseUrl);

  final http.Client _client;
  final NetworkConfig _config;
  final Uri _baseUri;

  @override
  Future<RestResponse<T>> get<T>(
    String path, {
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _send<T>(() => _client.get(uri, headers: _headers));
  }

  @override
  Future<RestResponse<T>> post<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _send<T>(
      () => _client.post(
        uri,
        headers: _headers,
        body: _encodeBody(body),
      ),
    );
  }

  @override
  Future<RestResponse<T>> put<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _send<T>(
      () => _client.put(
        uri,
        headers: _headers,
        body: _encodeBody(body),
      ),
    );
  }

  @override
  Future<RestResponse<T>> patch<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _send<T>(
      () => _client.patch(
        uri,
        headers: _headers,
        body: _encodeBody(body),
      ),
    );
  }

  @override
  Future<RestResponse<T>> delete<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    return _send<T>(
      () => _client.delete(
        uri,
        headers: _headers,
        body: _encodeBody(body),
      ),
    );
  }

  Future<RestResponse<T>> _send<T>(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request();
      final decoded = _decodeBody(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpStatusException(
          statusCode: response.statusCode,
          message: _resolveErrorMessage(decoded, response.statusCode),
          body: response.body,
        );
      }

      return RestResponse<T>(
        data: decoded as T,
        statusCode: response.statusCode,
      );
    } on SocketException catch (error) {
      throw NetworkException(
        'No se pudo conectar con el servidor: ${error.message}',
      );
    } on http.ClientException catch (error) {
      throw NetworkException(
        'Error de cliente HTTP: ${error.message}',
      );
    } on FormatException catch (error) {
      throw DataParsingException(
        'Respuesta con formato invalido: ${error.message}',
      );
    }
  }

  Uri _buildUri(String path, QueryParams? queryParameters) {
    final normalizedBasePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    final trimmedBasePath = normalizedBasePath.startsWith('/')
        ? normalizedBasePath.substring(1)
        : normalizedBasePath;

    final trimmedPath = path.startsWith('/') ? path.substring(1) : path;

    final combinedPath = <String>[
      if (trimmedBasePath.isNotEmpty) trimmedBasePath,
      if (trimmedPath.isNotEmpty) trimmedPath,
    ].join('/');

    return _baseUri.replace(
      path: '/$combinedPath',
      queryParameters: _normalizeQueryParameters(queryParameters),
    );
  }

  Map<String, String> get _headers {
    return <String, String>{
      'Content-Type': 'application/json',
      ..._config.defaultHeaders,
    };
  }

  String? _encodeBody(Object? body) {
    if (body == null) {
      return null;
    }

    if (body is String) {
      return body;
    }

    return jsonEncode(body);
  }

  Object? _decodeBody(String body) {
    if (body.isEmpty) {
      return null;
    }

    return jsonDecode(body);
  }

  String _resolveErrorMessage(Object? decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final value = decoded['message'] ?? decoded['error'] ?? decoded['detail'];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    if (decoded is String && decoded.trim().isNotEmpty) {
      return decoded;
    }

    return 'La solicitud HTTP fallo con estado $statusCode.';
  }

  Map<String, String>? _normalizeQueryParameters(QueryParams? queryParameters) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return null;
    }

    final map = <String, String>{};

    queryParameters.forEach((key, value) {
      if (value != null) {
        map[key] = value.toString();
      }
    });

    return map;
  }
}