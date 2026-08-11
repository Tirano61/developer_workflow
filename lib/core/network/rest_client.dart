typedef QueryParams = Map<String, dynamic>;

class RestResponse<T> {
  const RestResponse({
    required this.data,
    required this.statusCode,
  });

  final T data;
  final int statusCode;
}

abstract class RestClient {
  Future<RestResponse<T>> get<T>(
    String path, {
    QueryParams? queryParameters,
  });

  Future<RestResponse<T>> post<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  });

  Future<RestResponse<T>> put<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  });

  Future<RestResponse<T>> delete<T>(
    String path, {
    Object? body,
    QueryParams? queryParameters,
  });
}
