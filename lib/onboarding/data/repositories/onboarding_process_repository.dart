import '../../../bpm_framework/bpm_framework.dart';
import '../models/onboarding_variables.dart';
import '../mock/mock_bpm_service.dart';

/// Swap `MockBpmService()` for a real, HTTP-backed `BpmService` and this
/// repository talks to an actual BPM engine with zero other changes — the
/// bloc and every screen above it are unaffected.
class OnboardingProcessRepository extends ProcessRepository<OnboardingVariables> {
  OnboardingProcessRepository({BpmService<OnboardingVariables>? bpmService})
      : super(
          processDefinitionKey: 'merchant_onboarding_demo',
          bpmService: bpmService ?? MockBpmService(),
        );
}
