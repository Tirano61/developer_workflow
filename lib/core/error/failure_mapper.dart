import 'exceptions.dart';
import 'failure.dart';

Failure mapExceptionToFailure(Object error) {
  if (error is Failure) {
    return error;
  }

  if (error is ValidationException) {
    return ValidationFailure(error.message);
  }

  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }

  if (error is HttpStatusException) {
    return ServerFailure(
      statusCode: error.statusCode,
      message: error.message,
    );
  }

  if (error is DataParsingException) {
    return ParsingFailure(error.message);
  }

  return UnknownFailure(error.toString());
}