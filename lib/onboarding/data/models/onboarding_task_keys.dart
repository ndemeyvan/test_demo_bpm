/// `task_definition_key`s of the `merchant_onboarding_demo` BPMN process.
///
/// A BPM engine identifies each task by a stable key defined at deployment
/// time (in the `.bpmn` file). See `OnboardingTaskSwitcher` for where these
/// keys turn into screens, and `MockBpmEngine` for where they are produced.
abstract final class OnboardingTaskKeys {
  /// User task — form: name, email, amount, channel.
  static const String applicantInfo = 'applicant_info';

  /// User task — one branch of the parallel split after [applicantInfo].
  static const String uploadIdDocument = 'upload_id_document';

  /// User task — the other branch of the same parallel split. The process
  /// waits for both uploads (an AND-join) before moving on.
  static const String uploadProofOfAddress = 'upload_proof_of_address';

  /// Service task (automatic, no form) — computes `riskScore` and feeds
  /// the exclusive gateway that follows it.
  static const String riskScreening = 'risk_screening';

  /// User task — only reached when [riskScreening] finds a high risk score.
  static const String manualReview = 'manual_review';
}
