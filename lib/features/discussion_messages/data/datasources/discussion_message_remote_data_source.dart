import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/rest_client.dart';
import '../../domain/entities/discussion_message.dart';
import '../models/discussion_message_model.dart';

abstract class DiscussionMessageRemoteDataSource {
  Future<DiscussionMessagePageModel> getMessagesByDiscussion({
    required String discussionId,
    int page = 1,
    int limit = 50,
    DiscussionMessageType? type,
  });

  Future<DiscussionMessageModel> createMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String content,
  });

  Future<DiscussionMessageModel> createAttachmentMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String fileName,
    required List<int> fileBytes,
    String? content,
  });

  Future<DiscussionMessageModel> updateMessage({
    required String discussionId,
    required String messageId,
    required String content,
  });
}

class DiscussionMessageRemoteDataSourceImpl
    implements DiscussionMessageRemoteDataSource {
  DiscussionMessageRemoteDataSourceImpl({required RestClient restClient})
    : _restClient = restClient;

  final RestClient _restClient;

  @override
  Future<DiscussionMessagePageModel> getMessagesByDiscussion({
    required String discussionId,
    int page = 1,
    int limit = 50,
    DiscussionMessageType? type,
  }) async {
    final response = await _restClient.get<Object?>(
      ApiEndpoints.discussionMessagesByDiscussionId(
        Uri.encodeComponent(discussionId),
      ),
      queryParameters: _buildQueryParameters(
        page: page,
        limit: limit,
        type: type,
      ),
    );

    return DiscussionMessagePageModel.fromPayload(
      response.data,
      discussionIdFallback: discussionId,
    );
  }

  @override
  Future<DiscussionMessageModel> createMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String content,
  }) async {
    final payload = DiscussionMessageModel.forCreate(
      type: type,
      content: content,
    );

    final response = await _restClient.post<Object?>(
      ApiEndpoints.discussionMessagesByDiscussionId(
        Uri.encodeComponent(discussionId),
      ),
      body: payload.toCreateJson(),
    );

    return DiscussionMessageModel.fromPayload(
      response.data,
      discussionIdFallback: discussionId,
    );
  }

  @override
  Future<DiscussionMessageModel> createAttachmentMessage({
    required String discussionId,
    required DiscussionMessageType type,
    required String fileName,
    required List<int> fileBytes,
    String? content,
  }) async {
    final normalizedFileName = fileName.trim();
    if (normalizedFileName.isEmpty) {
      throw const ValidationException(
        'El nombre del archivo es obligatorio para subir adjuntos.',
      );
    }

    if (fileBytes.isEmpty) {
      throw const ValidationException(
        'El archivo seleccionado no contiene datos.',
      );
    }

    final payload = DiscussionMessageModel.forAttachmentUpload(
      type: type,
      content: content,
    );

    final response = await _restClient.postMultipart<Object?>(
      ApiEndpoints.discussionMessageFilesByDiscussionId(
        Uri.encodeComponent(discussionId),
      ),
      fields: payload.toAttachmentFormFields(),
      fileField: 'file',
      fileBytes: fileBytes,
      fileName: normalizedFileName,
    );

    return DiscussionMessageModel.fromPayload(
      response.data,
      discussionIdFallback: discussionId,
    );
  }

  @override
  Future<DiscussionMessageModel> updateMessage({
    required String discussionId,
    required String messageId,
    required String content,
  }) async {
    if (messageId.trim().isEmpty) {
      throw const ValidationException('A message id is required to update it.');
    }

    final payload = DiscussionMessageModel.forUpdate(content: content);

    final response = await _restClient.patch<Object?>(
      ApiEndpoints.discussionMessageByIds(
        Uri.encodeComponent(discussionId),
        Uri.encodeComponent(messageId),
      ),
      body: payload.toUpdateJson(),
    );

    return DiscussionMessageModel.fromPayload(
      response.data,
      discussionIdFallback: discussionId,
    );
  }

  QueryParams _buildQueryParameters({
    required int page,
    required int limit,
    DiscussionMessageType? type,
  }) {
    final params = <String, dynamic>{'page': page, 'limit': limit};

    if (type != null && type != DiscussionMessageType.unknown) {
      params['type'] = type.apiValue;
    }

    return params;
  }
}
