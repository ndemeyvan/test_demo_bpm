import '../../../bpm_framework/bpm_framework.dart';

/// Process variables for `merchant_onboarding_demo`.
///
/// These travel with the process instance from task to task: each task
/// reads some of them (to pre-fill its screen) and writes some back when
/// the user completes it. Numeric fields are typed `num?` — never
/// `int?`/`double?` — because a BPM engine serializes numbers
/// inconsistently depending on the last writer.
class OnboardingVariables extends Variable {
  final String? applicantName;
  final String? applicantEmail;
  final num? requestedAmount;

  final bool? documentUploaded;
  final String? documentName;

  /// Computed by the engine right after `upload_document` completes. The
  /// applicant never sets this — it only exists to drive the exclusive
  /// gateway that decides between auto-approval and `manual_review`.
  final num? riskScore;

  final String? reviewDecision; // 'approved' | 'rejected'
  final String? rejectionReason;
  final bool? autoApproved;

  const OnboardingVariables({
    this.applicantName,
    this.applicantEmail,
    this.requestedAmount,
    this.documentUploaded,
    this.documentName,
    this.riskScore,
    this.reviewDecision,
    this.rejectionReason,
    this.autoApproved,
  });

  OnboardingVariables copyWith({
    String? applicantName,
    String? applicantEmail,
    num? requestedAmount,
    bool? documentUploaded,
    String? documentName,
    num? riskScore,
    String? reviewDecision,
    String? rejectionReason,
    bool? autoApproved,
  }) {
    return OnboardingVariables(
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      documentUploaded: documentUploaded ?? this.documentUploaded,
      documentName: documentName ?? this.documentName,
      riskScore: riskScore ?? this.riskScore,
      reviewDecision: reviewDecision ?? this.reviewDecision,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      autoApproved: autoApproved ?? this.autoApproved,
    );
  }
}

extension OnboardingProcessX on Process<OnboardingVariables> {
  bool get isApproved => isEnded && processVariables.reviewDecision == 'approved';

  bool get isRejected => isEnded && processVariables.reviewDecision == 'rejected';
}
