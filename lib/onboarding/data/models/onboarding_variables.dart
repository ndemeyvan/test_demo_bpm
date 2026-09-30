import '../../../bpm_framework/bpm_framework.dart';

/// Process variables for `merchant_onboarding_demo`.
///
/// These travel with the process instance from task to task: each task
/// reads some of them (to pre-fill its form) and writes some back when the
/// user completes it. Numeric fields are typed `num?` — never
/// `int?`/`double?` — because a BPM engine serializes numbers
/// inconsistently depending on the last writer.
class OnboardingVariables extends Variable {
  final String? applicantName;
  final String? applicantEmail;
  final num? requestedAmount;
  final String? channel; // 'online' | 'agence'

  final bool? idDocumentUploaded;
  final String? idDocumentName;
  final bool? proofOfAddressUploaded;
  final String? proofOfAddressName;

  /// Computed by the `risk_screening` service task. No screen ever sets
  /// this — it only exists to drive the exclusive gateway that decides
  /// between auto-approval and `manual_review`.
  final num? riskScore;

  final String? reviewDecision; // 'approved' | 'rejected'
  final String? rejectionReason;
  final bool? autoApproved;

  const OnboardingVariables({
    this.applicantName,
    this.applicantEmail,
    this.requestedAmount,
    this.channel,
    this.idDocumentUploaded,
    this.idDocumentName,
    this.proofOfAddressUploaded,
    this.proofOfAddressName,
    this.riskScore,
    this.reviewDecision,
    this.rejectionReason,
    this.autoApproved,
  });

  OnboardingVariables copyWith({
    String? applicantName,
    String? applicantEmail,
    num? requestedAmount,
    String? channel,
    bool? idDocumentUploaded,
    String? idDocumentName,
    bool? proofOfAddressUploaded,
    String? proofOfAddressName,
    num? riskScore,
    String? reviewDecision,
    String? rejectionReason,
    bool? autoApproved,
  }) {
    return OnboardingVariables(
      applicantName: applicantName ?? this.applicantName,
      applicantEmail: applicantEmail ?? this.applicantEmail,
      requestedAmount: requestedAmount ?? this.requestedAmount,
      channel: channel ?? this.channel,
      idDocumentUploaded: idDocumentUploaded ?? this.idDocumentUploaded,
      idDocumentName: idDocumentName ?? this.idDocumentName,
      proofOfAddressUploaded: proofOfAddressUploaded ?? this.proofOfAddressUploaded,
      proofOfAddressName: proofOfAddressName ?? this.proofOfAddressName,
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
