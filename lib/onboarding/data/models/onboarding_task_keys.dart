/// `task_definition_key`s of the `merchant_onboarding_demo` BPMN process.
///
/// A BPM engine identifies each user task by a stable key defined at
/// deployment time (in the `.bpmn` file). See `OnboardingTaskSwitcher` for
/// where these keys turn into screens, and `MockBpmEngine` for where they
/// are produced.
abstract final class OnboardingTaskKeys {
  static const String applicantInfo = 'applicant_info';
  static const String uploadDocument = 'upload_document';
  static const String manualReview = 'manual_review';
}
