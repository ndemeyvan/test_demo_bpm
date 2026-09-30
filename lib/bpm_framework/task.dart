import 'form.dart';
import 'variable.dart';

/// Whether a task waits on a human ([userTask]) or runs by itself
/// ([serviceTask]) — e.g. a call to an external system. A [serviceTask]
/// carries no [Task.form]: there is nothing to ask a human.
enum TaskType { userTask, serviceTask }

/// One task currently active on a process instance — the BPM engine's way
/// of saying "here is what must happen next". A process can have more than
/// one [Task] active at once (see `Process.activeTask`, a list): that's how
/// a parallel gateway shows up — several branches waiting side by side
/// until every one of them completes.
///
/// [taskDefinitionKey] is the stable identifier a BPMN diagram gives each
/// task at deployment time. The app never switches screens by index or by
/// order — always by this key — so the engine stays free to reorder, skip,
/// or loop over tasks without an app release.
class Task<PV extends Variable> {
  final String id;
  final String taskDefinitionKey;
  final String name;
  final String? description;
  final String processInstanceId;
  final DateTime createTime;
  final PV processVariables;
  final TaskType type;
  final FormDefinition? form;

  const Task({
    required this.id,
    required this.taskDefinitionKey,
    required this.name,
    this.description,
    required this.processInstanceId,
    required this.createTime,
    required this.processVariables,
    this.type = TaskType.userTask,
    this.form,
  });
}
