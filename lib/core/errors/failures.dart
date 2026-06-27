import 'package:equatable/equatable.dart';

/// User-facing failure types. Carry a friendly [message] for the UI and an
/// optional [detail] for logs. Never expose a raw exception to the user.
sealed class Failure extends Equatable {
  final String message;
  final String? detail;
  const Failure(this.message, {this.detail});

  @override
  List<Object?> get props => [message, detail];
}

class NetworkFailure extends Failure {
  const NetworkFailure({String? detail})
      : super('You appear to be offline. Showing the last saved forecast.',
            detail: detail);
}

class ServerFailure extends Failure {
  const ServerFailure({String? detail})
      : super('The weather service is unavailable right now. Please retry.',
            detail: detail);
}

class CacheFailure extends Failure {
  const CacheFailure({String? detail})
      : super('No saved forecast available yet.', detail: detail);
}

class UnknownFailure extends Failure {
  const UnknownFailure({String? detail})
      : super('Something went wrong. Please try again.', detail: detail);
}
