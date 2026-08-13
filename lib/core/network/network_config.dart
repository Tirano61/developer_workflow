class NetworkConfig {
  const NetworkConfig({required this.baseUrl, this.defaultHeaders = const {}});

  final String baseUrl;
  final Map<String, String> defaultHeaders;

  factory NetworkConfig.fromEnvironment() {
    final headers = <String, String>{'Accept': 'application/json'};
    final apiBaseUrl = const String.fromEnvironment('API_BASE_URL');
    final useLocalApi = const bool.fromEnvironment(
      'USE_LOCAL_API',
      defaultValue: false,
    );

    return NetworkConfig(
      baseUrl:
          apiBaseUrl.isNotEmpty
              ? apiBaseUrl
              : (useLocalApi
              ? 'https://w4qb7jsw-3000.brs.devtunnels.ms/api/v1'
                  : 'http://24.144.109.91:3000/api/v1'),
      defaultHeaders: headers,
    );
  }
}
// flutter run --dart-define=USE_LOCAL_API=true