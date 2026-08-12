import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/tag.dart';
import '../../domain/usecases/create_tag.dart';
import '../../domain/usecases/get_tags.dart';
import 'tag_event.dart';
import 'tag_state.dart';

class TagBloc extends Bloc<TagEvent, TagState> {
  TagBloc({required GetTags getTags, required CreateTag createTag})
    : _getTags = getTags,
      _createTag = createTag,
      super(const TagState()) {
    on<LoadTagsEvent>(_onLoadTags);
    on<CreateTagEvent>(_onCreateTag);
  }

  final GetTags _getTags;
  final CreateTag _createTag;

  Future<void> _onLoadTags(LoadTagsEvent event, Emitter<TagState> emit) async {
    emit(state.copyWith(status: TagStatus.loading, errorMessage: ''));

    final result = await _getTags();

    if (result is Success<List<Tag>>) {
      emit(
        state.copyWith(
          status: TagStatus.success,
          tags: result.data,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<List<Tag>>) {
      emit(
        state.copyWith(
          status: TagStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCreateTag(
    CreateTagEvent event,
    Emitter<TagState> emit,
  ) async {
    emit(state.copyWith(status: TagStatus.loading, errorMessage: ''));

    final result = await _createTag(event.tag);

    if (result is Success<Tag>) {
      final created = result.data;
      emit(
        state.copyWith(
          status: TagStatus.success,
          tags: _mergeCreatedTag(state.tags, created),
          selectedTag: created,
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Tag>) {
      emit(
        state.copyWith(
          status: TagStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  List<Tag> _mergeCreatedTag(List<Tag> current, Tag created) {
    final createdId = created.id?.trim() ?? '';
    final createdName = created.name.trim().toLowerCase();

    final merged = <Tag>[];
    var replaced = false;

    for (final item in current) {
      final idMatch = createdId.isNotEmpty && (item.id?.trim() == createdId);
      final nameMatch =
          createdId.isEmpty && item.name.trim().toLowerCase() == createdName;

      if (idMatch || nameMatch) {
        merged.add(created);
        replaced = true;
      } else {
        merged.add(item);
      }
    }

    if (!replaced) {
      merged.add(created);
    }

    merged.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return merged;
  }
}
