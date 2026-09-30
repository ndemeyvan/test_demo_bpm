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

  /// [variablesToJson] serializes [processVariables] — a generic `Task<PV>`
  /// has no way to know how to turn an arbitrary `PV` into JSON by itself,
  /// so the caller (ultimately the concrete process, e.g.
  /// `OnboardingVariables.toJson`) provides it.
  Map<String, dynamic> toJson(Map<String, dynamic> Function(PV) variablesToJson) {
    return {
      'id': id,
      'taskDefinitionKey': taskDefinitionKey,
      'name': name,
      'description': description,
      'processInstanceId': processInstanceId,
      'createTime': createTime.toIso8601String(),
      'processVariables': variablesToJson(processVariables),
      'type': type.name,
      'form': form?.toJson(),
    };
  }

  static Task<PV> fromJson<PV extends Variable>(
    Map<String, dynamic> json,
    PV Function(Map<String, dynamic>) variablesFromJson,
  ) {
    return Task<PV>(
      id: json['id'] as String,
      taskDefinitionKey: json['taskDefinitionKey'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      processInstanceId: json['processInstanceId'] as String,
      createTime: DateTime.parse(json['createTime'] as String),
      processVariables: variablesFromJson(json['processVariables'] as Map<String, dynamic>),
      type: TaskType.values.byName(json['type'] as String),
      form: json['form'] != null
          ? FormDefinition.fromJson(json['form'] as Map<String, dynamic>)
          : null,
    );
  }
}
