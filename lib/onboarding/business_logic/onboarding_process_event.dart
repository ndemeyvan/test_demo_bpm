part of 'onboarding_process_bloc.dart';

sealed class OnboardingProcessEvent extends ProcessEvent {
  const OnboardingProcessEvent();
}

/// Starts a brand new process instance — the BPM equivalent of a start
/// event firing. Dispatched once when the demo screen opens.
final class StartOnboardingProcess extends OnboardingProcessEvent {
  const StartOnboardingProcess();
}

/// Completes the `applicant_info` user task.
final class SubmitApplicantInfo extends OnboardingProcessEvent {
  final String applicantName;
  final String applicantEmail;
  final num requestedAmount;

  const SubmitApplicantInfo({
    required this.applicantName,
    required this.applicantEmail,
    required this.requestedAmount,
  });
}

/// Completes the `upload_document` user task.
final class SubmitDocumentUpload extends OnboardingProcessEvent {
  final String documentName;

  const SubmitDocumentUpload({required this.documentName});
}

/// Completes the `manual_review` user task with the compliance officer's
/// decision — mirrors the "outcome" a BPMN user-task form submits.
final class SubmitManualReviewDecision extends OnboardingProcessEvent {
  final bool approved;
  final String? reason;

  const SubmitManualReviewDecision({required this.approved, this.reason});
}

/// Abandons the current instance and starts a fresh one.
final class RestartOnboardingProcess extends OnboardingProcessEvent {
  const RestartOnboardingProcess();
}
