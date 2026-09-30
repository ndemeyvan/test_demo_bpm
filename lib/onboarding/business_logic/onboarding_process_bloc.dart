import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bpm_framework/bpm_framework.dart';
import '../data/models/onboarding_task_keys.dart';
import '../data/models/onboarding_variables.dart';
import '../data/repositories/onboarding_process_repository.dart';

part 'onboarding_process_event.dart';
part 'onboarding_process_state.dart';

/// The "process code" for the merchant-onboarding demo.
///
/// It never contains screen logic — only the mapping between user actions
/// (events) and BPM engine calls (`repository.startProcess` / `execTask`).
/// The UI reacts to whatever `state.process.activeTaskDefinitionKey` is;
/// see `OnboardingTaskSwitcher` for the other half of that mechanism.
class OnboardingProcessBloc extends Bloc<OnboardingProcessEvent, OnboardingProcessState> {
  final OnboardingProcessRepository repository;

  OnboardingProcessBloc({required this.repository})
      : super(const OnboardingProcessInitial()) {
    on<StartOnboardingProcess>(_onStart);
    on<SubmitApplicantInfo>(_onSubmitApplicantInfo);
    on<SubmitDocumentUpload>(_onSubmitDocumentUpload);
    on<SubmitManualReviewDecision>(_onSubmitManualReviewDecision);
    on<RestartOnboardingProcess>(_onStart);
  }

  Future<void> _onStart(
    OnboardingProcessEvent event,
    Emitter<OnboardingProcessState> emit,
  ) async {
    emit(const OnboardingProcessLoading());
    await _run(emit, () => repository.startProcess());
  }

  Future<void> _onSubmitApplicantInfo(
    SubmitApplicantInfo event,
    Emitter<OnboardingProcessState> emit,
  ) async {
    emit(OnboardingProcessLoading(process: state.process));
    await _run(
      emit,
      () => repository.execTask(
        processInstanceId: state.process!.processInstanceId,
        taskInstanceId: _activeTaskId(OnboardingTaskKeys.applicantInfo),
        outcome: 'submit',
        body: {
          'applicantName': event.applicantName,
          'applicantEmail': event.applicantEmail,
          'requestedAmount': event.requestedAmount,
        },
      ),
    );
  }

  Future<void> _onSubmitDocumentUpload(
    SubmitDocumentUpload event,
    Emitter<OnboardingProcessState> emit,
  ) async {
    emit(OnboardingProcessLoading(process: state.process));
    await _run(
      emit,
      () => repository.execTask(
        processInstanceId: state.process!.processInstanceId,
        taskInstanceId: _activeTaskId(OnboardingTaskKeys.uploadDocument),
        outcome: 'submit',
        body: {'documentName': event.documentName},
      ),
    );
  }

  Future<void> _onSubmitManualReviewDecision(
    SubmitManualReviewDecision event,
    Emitter<OnboardingProcessState> emit,
  ) async {
    emit(OnboardingProcessLoading(process: state.process));
    await _run(
      emit,
      () => repository.execTask(
        processInstanceId: state.process!.processInstanceId,
        taskInstanceId: _activeTaskId(OnboardingTaskKeys.manualReview),
        outcome: event.approved ? 'approve' : 'reject',
        body: {if (event.reason != null) 'reason': event.reason!},
      ),
    );
  }

  /// Every `execTask` call needs the id of the *current* active task, never
  /// a cached one — otherwise the engine rejects it (`com-task-0002`, see
  /// `MockBpmEngine.completeTask`).
  String _activeTaskId(String expectedTaskKey) {
    final tasks = state.process?.activeTask ?? const [];
    for (final task in tasks) {
      if (task.taskDefinitionKey == expectedTaskKey) return task.id;
    }
    return tasks.isNotEmpty ? tasks.first.id : '';
  }

  Future<void> _run(
    Emitter<OnboardingProcessState> emit,
    Future<Process<OnboardingVariables>> Function() action,
  ) async {
    try {
      final process = await action();
      emit(OnboardingProcessLoaded(process: process));
    } on ProcessError<Process<OnboardingVariables>> catch (e) {
      emit(OnboardingProcessFailure(process: e.process ?? state.process, message: e.message));
    }
  }
}
