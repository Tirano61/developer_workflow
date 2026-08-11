abstract class Failure {
  const Failure(this.message);

  final String message;
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Ha ocurrido un error inesperado.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No se pudo establecer conexion con el servidor.',
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure({
    required this.statusCode,
    required String message,
  }) : super(message);

  final int statusCode;
}

class ParsingFailure extends Failure {
  const ParsingFailure([
    super.message = 'No se pudo interpretar la respuesta del servidor.',
  ]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Los datos enviados no son validos.']);
}
