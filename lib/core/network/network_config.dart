class NetworkConfig {
  const NetworkConfig({required this.baseUrl, this.defaultHeaders = const {}});

  final String baseUrl;
  final Map<String, String> defaultHeaders;

  factory NetworkConfig.fromEnvironment() {
    final headers = <String, String>{'Accept': 'application/json'};

    return NetworkConfig(
      baseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://24.144.109.91:3000/api/v1',
      ),
      defaultHeaders: headers,
    );
  }
}
