import 'bpm_service.dart';
import 'process.dart';
import 'variable.dart';

/// Thin wrapper the rest of the app talks to instead of [BpmService]
/// directly. Keeping this layer separate — rather than calling
/// [BpmService] from the bloc — is what makes swapping the engine
/// implementation (mock ↔ real) painless: only the constructor argument
/// changes, nothing that calls the repository has to know.
class ProcessRepository<PV extends Variable> {
  final String processDefinitionKey;
  final BpmService<PV> bpmService;

  const ProcessRepository({required this.processDefinitionKey, required this.bpmService});

  Future<Process<PV>> startProcess({Map<String, dynamic>? body}) {
    return bpmService.startProcess(body ?? {});
  }

  Future<Process<PV>> fetchProcess(String processInstanceId) {
    return bpmService.fetchProcess(processInstanceId);
  }

  Future<Process<PV>> execTask({
    required String processInstanceId,
    required String taskInstanceId,
    required String outcome,
    required Map<String, dynamic> body,
  }) {
    return bpmService.completeTask(
      processInstanceId: processInstanceId,
      taskInstanceId: taskInstanceId,
      outcome: outcome,
      body: body,
    );
  }
}
