abstract class Failure {
  const Failure({this.message});

  final String? message;
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.message});
}
