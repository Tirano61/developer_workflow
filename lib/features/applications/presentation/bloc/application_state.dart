import '../../domain/entities/application.dart';

enum ApplicationStatus { initial, loading, success, error }

class ApplicationState {
  const ApplicationState({
    this.status = ApplicationStatus.initial,
    this.applications = const [],
    this.selectedApplication,
    this.errorMessage = '',
  });

  final ApplicationStatus status;
  final List<Application> applications;
  final Application? selectedApplication;
  final String errorMessage;

  ApplicationState copyWith({
    ApplicationStatus? status,
    List<Application>? applications,
    Application? selectedApplication,
    bool clearSelectedApplication = false,
    String? errorMessage,
  }) {
    return ApplicationState(
      status: status ?? this.status,
      applications: applications ?? this.applications,
      selectedApplication: clearSelectedApplication
          ? null
          : selectedApplication ?? this.selectedApplication,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}