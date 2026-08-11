import '../../../../core/error/exceptions.dart';
import '../../domain/entities/discussion_message.dart';
import '../../domain/entities/discussion_message_page.dart';

class DiscussionMessageAuthorModel {
  const DiscussionMessageAuthorModel({
    required this.id,
    this.email,
    this.fullName,
  });

  final String id;
  final String? email;
  final String? fullName;

  factory DiscussionMessageAuthorModel.fromJson(Map<String, dynamic> json) {
    final id = _readString(json, const ['id', '_id', 'uuid']);
    if (id == null || id.isEmpty) {
      throw const DataParsingException(
        'Discussion message author id is missing in backend payload.',
      );
    }

    return DiscussionMessageAuthorModel(
      id: id,
      email: _readString(json, const ['email', 'mail']),
      fullName: _readString(json, const ['fullName', 'full_name', 'name']),
    );
  }

  DiscussionMessageAuthor toEntity() {
    return DiscussionMessageAuthor(id: id, email: email, fullName: fullName);
  }

  factory DiscussionMessageAuthorModel.fromEntity(
    DiscussionMessageAuthor entity,
  ) {
    return DiscussionMessageAuthorModel(
      id: entity.id,
      email: entity.email,
      fullName: entity.fullName,
    );
  }
}

class DiscussionMessageModel {
  const DiscussionMessageModel({
    this.id,
    this.discussionId,
    this.author,
    required this.type,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String? discussionId;
  final DiscussionMessageAuthorModel? author;
  final DiscussionMessageType type;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DiscussionMessageModel.fromJson(
    Map<String, dynamic> json, {
    String? discussionIdFallback,
  }) {
    final id = _readString(json, const ['id', '_id', 'uuid']);
    if (id == null || id.isEmpty) {
      throw const DataParsingException(
        'Discussion message id is missing in backend payload.',
      );
    }

    final discussionId = _readDiscussionId(json, discussionIdFallback);
    if (discussionId == null || discussionId.isEmpty) {
      throw const DataParsingException(
        'Discussion message discussionId is missing in backend payload.',
      );
    }

    final author = _readAuthor(json);
    if (author == null) {
      throw const DataParsingException(
        'Discussion message author is missing in backend payload.',
      );
    }

    final content = _readString(json, const ['content', 'message', 'text']);
    if (content == null || content.isEmpty) {
      throw const DataParsingException(
        'Discussion message content is missing in backend payload.',
      );
    }

    return DiscussionMessageModel(
      id: id,
      discussionId: discussionId,
      author: author,
      type: DiscussionMessageTypeX.fromApiValue(
        _readString(json, const ['type']),
      ),
      content: content,
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: _readDateTime(json, const ['updatedAt', 'updated_at']),
    );
  }

  factory DiscussionMessageModel.forCreate({
    required DiscussionMessageType type,
    required String content,
  }) {
    return DiscussionMessageModel(type: type, content: content);
  }

  factory DiscussionMessageModel.forUpdate({required String content}) {
    return DiscussionMessageModel(
      type: DiscussionMessageType.text,
      content: content,
    );
  }

  factory DiscussionMessageModel.fromEntity(DiscussionMessage entity) {
    return DiscussionMessageModel(
      id: entity.id,
      discussionId: entity.discussionId,
      author: DiscussionMessageAuthorModel.fromEntity(entity.author),
      type: entity.type,
      content: entity.content,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static DiscussionMessageModel fromPayload(
    Object? payload, {
    required String discussionIdFallback,
  }) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return DiscussionMessageModel.fromJson(
          data,
          discussionIdFallback: discussionIdFallback,
        );
      }

      final message = payload['message'];
      if (message is Map<String, dynamic>) {
        return DiscussionMessageModel.fromJson(
          message,
          discussionIdFallback: discussionIdFallback,
        );
      }

      final discussionMessage = payload['discussionMessage'];
      if (discussionMessage is Map<String, dynamic>) {
        return DiscussionMessageModel.fromJson(
          discussionMessage,
          discussionIdFallback: discussionIdFallback,
        );
      }

      return DiscussionMessageModel.fromJson(
        payload,
        discussionIdFallback: discussionIdFallback,
      );
    }

    throw const DataParsingException(
      'Unexpected payload format for discussion message item response.',
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'type': type == DiscussionMessageType.unknown
          ? DiscussionMessageType.text.apiValue
          : type.apiValue,
      'content': content.trim(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{'content': content.trim()};
  }

  DiscussionMessage toEntity() {
    final resolvedId = id;
    final resolvedDiscussionId = discussionId;
    final resolvedAuthor = author;

    if (resolvedId == null ||
        resolvedId.isEmpty ||
        resolvedDiscussionId == null ||
        resolvedDiscussionId.isEmpty ||
        resolvedAuthor == null) {
      throw const DataParsingException(
        'Discussion message model is missing required fields to map into entity.',
      );
    }

    return DiscussionMessage(
      id: resolvedId,
      discussionId: resolvedDiscussionId,
      author: resolvedAuthor.toEntity(),
      type: type == DiscussionMessageType.unknown
          ? DiscussionMessageType.text
          : type,
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static String? _readDiscussionId(
    Map<String, dynamic> json,
    String? discussionIdFallback,
  ) {
    final direct = _readString(json, const ['discussionId', 'discussion_id']);
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final rawDiscussion = _readFirst(json, const ['discussion']);
    if (rawDiscussion is String && rawDiscussion.trim().isNotEmpty) {
      return rawDiscussion.trim();
    }

    if (rawDiscussion is Map<String, dynamic>) {
      final nestedId = _readString(rawDiscussion, const ['id', '_id', 'uuid']);
      if (nestedId != null && nestedId.isNotEmpty) {
        return nestedId;
      }
    }

    final fallback = discussionIdFallback?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }

  static DiscussionMessageAuthorModel? _readAuthor(Map<String, dynamic> json) {
    final authorId = _readString(json, const ['authorId', 'author_id']);

    final rawAuthor = _readFirst(json, const ['author', 'createdBy', 'user']);
    if (rawAuthor is Map<String, dynamic>) {
      return DiscussionMessageAuthorModel.fromJson(rawAuthor);
    }

    if (rawAuthor is String && rawAuthor.trim().isNotEmpty) {
      return DiscussionMessageAuthorModel(id: rawAuthor.trim());
    }

    if (authorId != null && authorId.isNotEmpty) {
      return DiscussionMessageAuthorModel(id: authorId);
    }

    return null;
  }
}

class DiscussionMessagePageModel {
  const DiscussionMessagePageModel({
    required this.data,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  final List<DiscussionMessageModel> data;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  factory DiscussionMessagePageModel.fromPayload(
    Object? payload, {
    required String discussionIdFallback,
  }) {
    if (payload is List) {
      final parsed = payload
          .map(
            (item) => DiscussionMessageModel.fromJson(
              _asMap(item),
              discussionIdFallback: discussionIdFallback,
            ),
          )
          .toList(growable: false);

      return DiscussionMessagePageModel(
        data: parsed,
        page: 1,
        limit: parsed.isEmpty ? 50 : parsed.length,
        total: parsed.length,
        totalPages: parsed.isEmpty ? 0 : 1,
      );
    }

    if (payload is Map<String, dynamic>) {
      final parsed = _extractList(payload)
          .map(
            (item) => DiscussionMessageModel.fromJson(
              _asMap(item),
              discussionIdFallback: discussionIdFallback,
            ),
          )
          .toList(growable: false);

      final page = _readInt(payload, const ['page']) ?? 1;
      final limit = _readInt(payload, const ['limit']) ?? 50;
      final total = _readInt(payload, const ['total']) ?? parsed.length;
      final totalPages =
          _readInt(payload, const ['totalPages', 'total_pages']) ??
          (limit > 0 ? (total / limit).ceil() : 0);

      return DiscussionMessagePageModel(
        data: parsed,
        page: page,
        limit: limit,
        total: total,
        totalPages: totalPages,
      );
    }

    throw const DataParsingException(
      'Unexpected payload format for discussion message list response.',
    );
  }

  DiscussionMessagePage toEntity() {
    return DiscussionMessagePage(
      data: data.map((item) => item.toEntity()).toList(growable: false),
      page: page,
      limit: limit,
      total: total,
      totalPages: totalPages,
    );
  }

  static List<dynamic> _extractList(Map<String, dynamic> map) {
    final data = map['data'];
    if (data is List) {
      return data;
    }

    final messages = map['messages'];
    if (messages is List) {
      return messages;
    }

    final items = map['items'];
    if (items is List) {
      return items;
    }

    final results = map['results'];
    if (results is List) {
      return results;
    }

    throw const DataParsingException(
      'Discussion message list response does not include a data array.',
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  throw const DataParsingException(
    'Unexpected item format while parsing discussion message payload.',
  );
}

Object? _readFirst(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return json[key];
    }
  }

  return null;
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  final value = _readFirst(json, keys);
  if (value == null) {
    return null;
  }

  final parsed = value.toString().trim();
  if (parsed.isEmpty) {
    return null;
  }

  return parsed;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  final value = _readFirst(json, keys);
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim());
  }

  return null;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value);
}
