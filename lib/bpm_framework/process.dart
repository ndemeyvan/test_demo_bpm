import 'task.dart';
import 'variable.dart';

/// A running (or finished) instance of a BPM process.
///
/// [activeTask] holds whichever user task(s) the engine is currently
/// waiting on — empty once the process has reached an end event
/// ([isEnded]). [activeTaskDefinitionKey] is a convenience for the common
/// case of exactly one active task; see `OnboardingTaskSwitcher` for how
/// the UI handles several at once (a parallel gateway).
class Process<PV extends Variable> {
  final String processInstanceId;
  final String processDefinitionKey;
  final bool isEnded;
  final DateTime startTime;
  final PV processVariables;
  final List<Task<PV>> activeTask;

  const Process({
    required this.processInstanceId,
    required this.processDefinitionKey,
    required this.isEnded,
    required this.startTime,
    required this.processVariables,
    this.activeTask = const [],
  });

  String? get activeTaskDefinitionKey =>
      activeTask.isEmpty ? null : activeTask.first.taskDefinitionKey;

  /// [variablesToJson] serializes [processVariables] — see the same note
  /// on `Task.toJson`.
  Map<String, dynamic> toJson(Map<String, dynamic> Function(PV) variablesToJson) {
    return {
      'processInstanceId': processInstanceId,
      'processDefinitionKey': processDefinitionKey,
      'isEnded': isEnded,
      'startTime': startTime.toIso8601String(),
      'processVariables': variablesToJson(processVariables),
      'activeTask': activeTask.map((t) => t.toJson(variablesToJson)).toList(),
    };
  }

  static Process<PV> fromJson<PV extends Variable>(
    Map<String, dynamic> json,
    PV Function(Map<String, dynamic>) variablesFromJson,
  ) {
    return Process<PV>(
      processInstanceId: json['processInstanceId'] as String,
      processDefinitionKey: json['processDefinitionKey'] as String,
      isEnded: json['isEnded'] as bool,
      startTime: DateTime.parse(json['startTime'] as String),
      processVariables: variablesFromJson(json['processVariables'] as Map<String, dynamic>),
      activeTask: (json['activeTask'] as List)
          .map((t) => Task.fromJson<PV>(t as Map<String, dynamic>, variablesFromJson))
          .toList(),
    );
  }
}
