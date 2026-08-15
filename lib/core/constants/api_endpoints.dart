class ApiEndpoints {
  const ApiEndpoints._();

  static const String authLogin = '/auth/login';

  static const String _developWorkflow = '/develop-workflow';

  static const String applications = '$_developWorkflow/applications';
  static const String indicators = '$_developWorkflow/indicators';
  static const String tags = '$_developWorkflow/tags';
  static const String discussions = '$_developWorkflow/discussions';
    static const String developers = '$_developWorkflow/developers';

  static String applicationById(String id) => '$applications/$id';

  static String indicatorById(String id) => '$indicators/$id';

  static String discussionById(String id) => '$discussions/$id';

  static String discussionStatusById(String id) => '${discussionById(id)}/status';

    static String discussionReadById(String id) => '${discussionById(id)}/read';

  static String discussionAssignmentsById(String id) =>
      '${discussionById(id)}/assignments';

  static String discussionAssignmentByIds(String id, String developerUserId) =>
      '${discussionAssignmentsById(id)}/$developerUserId';

  static String discussionMessagesByDiscussionId(String discussionId) =>
      '${discussionById(discussionId)}/messages';

  static String discussionMessageFilesByDiscussionId(String discussionId) =>
      '${discussionMessagesByDiscussionId(discussionId)}/files';

  static String discussionMessageByIds(String discussionId, String messageId) =>
      '${discussionMessagesByDiscussionId(discussionId)}/$messageId';
}
