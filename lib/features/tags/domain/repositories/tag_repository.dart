import '../../../../core/error/result.dart';
import '../entities/tag.dart';

abstract class TagRepository {
  Future<Result<List<Tag>>> getTags();

  Future<Result<Tag>> createTag(Tag tag);
}
