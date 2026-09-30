part of 'onboarding_process_bloc.dart';

sealed class OnboardingProcessEvent extends ProcessEvent {
  const OnboardingProcessEvent();
}

/// Starts a brand new process instance — the BPM equivalent of a start
/// event firing. Dispatched once when the demo screen opens.
final class StartOnboardingProcess extends OnboardingProcessEvent {
  const StartOnboardingProcess();
}

/// Completes any user task generically.
///
/// The bloc doesn't need to know the shape of each task's form — it just
/// forwards whatever `DynamicFormView` collected, the same way a real BPM
/// client posts a task's form values without caring what they mean.
/// [outcome] is which button the user pressed (a plain "submit" for a
/// single-button form, or "approve"/"reject" for `manual_review`).
final class SubmitTaskForm extends OnboardingProcessEvent {
  final String taskDefinitionKey;
  final String outcome;
  final Map<String, dynamic> values;

  const SubmitTaskForm({
    required this.taskDefinitionKey,
    required this.outcome,
    required this.values,
  });
}

/// Advances a service task (no human input) once its simulated processing
/// delay elapses — see `StepAutomaticProcessingView`.
final class AdvanceAutomaticTask extends OnboardingProcessEvent {
  final String taskDefinitionKey;

  const AdvanceAutomaticTask({required this.taskDefinitionKey});
}

/// Abandons the current instance and starts a fresh one.
final class RestartOnboardingProcess extends OnboardingProcessEvent {
  const RestartOnboardingProcess();
}
