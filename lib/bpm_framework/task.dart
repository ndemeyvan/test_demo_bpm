import 'variable.dart';

/// One user task currently waiting on a human — the BPM engine's way of
/// saying "here is what must happen next".
///
/// [taskDefinitionKey] is the stable identifier a BPMN diagram gives each
/// task at deployment time. The app never switches screens by index or by
/// order — always by this key — so the engine stays free to reorder, skip,
/// or loop over tasks without an app release.
class Task<PV extends Variable> {
  final String id;
  final String taskDefinitionKey;
  final String name;
  final String processInstanceId;
  final DateTime createTime;
  final PV processVariables;

  const Task({
    required this.id,
    required this.taskDefinitionKey,
    required this.name,
    required this.processInstanceId,
    required this.createTime,
    required this.processVariables,
  });
}
