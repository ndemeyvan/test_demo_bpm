import '../../../bpm_framework/bpm_framework.dart';
import '../models/onboarding_variables.dart';
import 'mock_bpm_engine.dart';

/// Implements the [BpmService] contract using [MockBpmEngine] instead of a
/// network call.
///
/// [ProcessRepository] only ever talks to a [BpmService] — it never knows
/// whether that service is real or mocked. Swapping this class in for an
/// HTTP-backed implementation is therefore the *only* change needed to run
/// an entire BPM screen without a backend: nothing above the repository
/// (the bloc, the screens, the screen-switching logic) has to know.
class MockBpmService implements BpmService<OnboardingVariables> {
  @override
  Future<Process<OnboardingVariables>> startProcess(Map<String, dynamic> body) {
    return MockBpmEngine.instance.start(body);
  }

  @override
  Future<Process<OnboardingVariables>> fetchProcess(String processInstanceId) {
    return MockBpmEngine.instance.fetch(processInstanceId);
  }

  @override
  Future<Process<OnboardingVariables>> completeTask({
    required String processInstanceId,
    required String taskInstanceId,
    required String outcome,
    required Map<String, dynamic> body,
  }) {
    return MockBpmEngine.instance.completeTask(
      processInstanceId: processInstanceId,
      taskInstanceId: taskInstanceId,
      outcome: outcome,
      body: body,
    );
  }
}
