import 'task.dart';
import 'variable.dart';

/// A running (or finished) instance of a BPM process.
///
/// [activeTask] holds whichever user task the engine is currently waiting
/// on — empty once the process has reached an end event ([isEnded]).
/// [activeTaskDefinitionKey] is the one field the UI needs to decide which
/// screen to show next; see `OnboardingTaskSwitcher`.
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
}
