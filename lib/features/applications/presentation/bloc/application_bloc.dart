import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/application.dart';
import '../../domain/usecases/create_application.dart';
import '../../domain/usecases/get_application.dart';
import '../../domain/usecases/get_applications.dart';
import '../../domain/usecases/update_application.dart';
import 'application_event.dart';
import 'application_state.dart';

class ApplicationBloc extends Bloc<ApplicationEvent, ApplicationState> {
  ApplicationBloc({
    required GetApplications getApplications,
    required GetApplication getApplication,
    required CreateApplication createApplication,
    required UpdateApplication updateApplication,
  })  : _getApplications = getApplications,
        _getApplication = getApplication,
        _createApplication = createApplication,
        _updateApplication = updateApplication,
        super(const ApplicationState()) {
    on<LoadApplicationsEvent>(_onLoadApplications);
    on<LoadApplicationEvent>(_onLoadApplication);
    on<CreateApplicationEvent>(_onCreateApplication);
    on<UpdateApplicationEvent>(_onUpdateApplication);
  }

  final GetApplications _getApplications;
  final GetApplication _getApplication;
  final CreateApplication _createApplication;
  final UpdateApplication _updateApplication;

  Future<void> _onLoadApplications(
    LoadApplicationsEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ApplicationStatus.loading,
        errorMessage: '',
        clearSelectedApplication: true,
      ),
    );

    final result = await _getApplications();

    if (result is Success<List<Application>>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          applications: result.data,
          errorMessage: '',
          clearSelectedApplication: true,
        ),
      );
      return;
    }

    if (result is FailureResult<List<Application>>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onLoadApplication(
    LoadApplicationEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ApplicationStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _getApplication(event.id);

    if (result is Success<Application>) {
      final selected = result.data;
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          selectedApplication: selected,
          applications: _upsertById(state.applications, selected),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Application>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onCreateApplication(
    CreateApplicationEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ApplicationStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _createApplication(event.application);

    if (result is Success<Application>) {
      final created = result.data;
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          selectedApplication: created,
          applications: _upsertById(state.applications, created),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Application>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  Future<void> _onUpdateApplication(
    UpdateApplicationEvent event,
    Emitter<ApplicationState> emit,
  ) async {
    emit(
      state.copyWith(
        status: ApplicationStatus.loading,
        errorMessage: '',
      ),
    );

    final result = await _updateApplication(event.application);

    if (result is Success<Application>) {
      final updated = result.data;
      emit(
        state.copyWith(
          status: ApplicationStatus.success,
          selectedApplication: updated,
          applications: _upsertById(state.applications, updated),
          errorMessage: '',
        ),
      );
      return;
    }

    if (result is FailureResult<Application>) {
      emit(
        state.copyWith(
          status: ApplicationStatus.error,
          errorMessage: result.failure.message,
        ),
      );
    }
  }

  List<Application> _upsertById(
    List<Application> current,
    Application application,
  ) {
    final next = List<Application>.from(current);
    final index = next.indexWhere(
      (item) =>
          item.id != null &&
          application.id != null &&
          item.id == application.id,
    );

    if (index >= 0) {
      next[index] = application;
      return List<Application>.unmodifiable(next);
    }

    next.add(application);
    return List<Application>.unmodifiable(next);
  }
}