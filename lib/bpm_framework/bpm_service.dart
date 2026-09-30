import 'process.dart';
import 'variable.dart';

/// Everything a BPM engine can be asked to do, from the app's point of
/// view. [ProcessRepository] only ever depends on this interface — never on
/// how it's implemented.
///
/// A production implementation would call a REST API in front of a real
/// engine (Flowable, Activiti, Camunda…). This demo's `MockBpmEngine`
/// implements it entirely in memory instead, through `MockBpmService`. Swap
/// one implementation for the other and nothing above [ProcessRepository]
/// has to change.
abstract class BpmService<PV extends Variable> {
  Future<Process<PV>> startProcess(Map<String, dynamic> body);

  Future<Process<PV>> fetchProcess(String processInstanceId);

  Future<Process<PV>> completeTask({
    required String processInstanceId,
    required String taskInstanceId,
    required String outcome,
    required Map<String, dynamic> body,
  });
}
