import '../../domain/entities/tag.dart';

sealed class TagEvent {
  const TagEvent();
}

class LoadTagsEvent extends TagEvent {
  const LoadTagsEvent();
}

class CreateTagEvent extends TagEvent {
  const CreateTagEvent(this.tag);

  final Tag tag;
}
