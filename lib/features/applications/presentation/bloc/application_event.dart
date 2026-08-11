import '../../domain/entities/application.dart';

sealed class ApplicationEvent {
  const ApplicationEvent();
}

class LoadApplicationsEvent extends ApplicationEvent {
  const LoadApplicationsEvent();
}

class LoadApplicationEvent extends ApplicationEvent {
  const LoadApplicationEvent(this.id);

  final String id;
}

class CreateApplicationEvent extends ApplicationEvent {
  const CreateApplicationEvent(this.application);

  final Application application;
}

class UpdateApplicationEvent extends ApplicationEvent {
  const UpdateApplicationEvent(this.application);

  final Application application;
}