import '../../domain/entities/application.dart';

class ApplicationModel {
  const ApplicationModel({
    this.id,
    required this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ApplicationModel.fromJson(Map<String, dynamic> json) {
    return ApplicationModel(
      id: _readString(json, const ['id', '_id', 'uuid']),
      name: _readString(
            json,
            const ['name', 'title', 'applicationName'],
          ) ??
          '',
      description: _readString(json, const ['description', 'detail']),
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
      updatedAt: _readDateTime(json, const ['updatedAt', 'updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'description': description,
    };

    if (id != null && id!.isNotEmpty) {
      map['id'] = id;
    }

    return map;
  }

  Application toEntity() {
    return Application(
      id: id,
      name: name,
      description: description,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ApplicationModel.fromEntity(Application entity) {
    return ApplicationModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      final parsed = value.toString().trim();
      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    return null;
  }

  static DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
    final value = _readString(json, keys);
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
  }
}