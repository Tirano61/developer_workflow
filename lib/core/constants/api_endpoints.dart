class ApiEndpoints {
  const ApiEndpoints._();

  static const String _developWorkflow = '/develop-workflow';

  static const String applications = '$_developWorkflow/applications';
  static const String indicators = '$_developWorkflow/indicators';
  static const String discussions = '$_developWorkflow/discussions';

  static String applicationById(String id) => '$applications/$id';

  static String indicatorById(String id) => '$indicators/$id';

  static String discussionById(String id) => '$discussions/$id';
}
