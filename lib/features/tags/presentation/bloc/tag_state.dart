import '../../domain/entities/tag.dart';

enum TagStatus { initial, loading, success, error }

class TagState {
  const TagState({
    this.status = TagStatus.initial,
    this.tags = const [],
    this.selectedTag,
    this.errorMessage = '',
  });

  final TagStatus status;
  final List<Tag> tags;
  final Tag? selectedTag;
  final String errorMessage;

  TagState copyWith({
    TagStatus? status,
    List<Tag>? tags,
    Tag? selectedTag,
    String? errorMessage,
  }) {
    return TagState(
      status: status ?? this.status,
      tags: tags ?? this.tags,
      selectedTag: selectedTag ?? this.selectedTag,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
