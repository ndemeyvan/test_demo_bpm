/// Thrown by a [BpmService] when the engine refuses a call — an invalid
/// form submission, a stale task, an unknown process instance, etc.
///
/// Carries the process state as it was *before* the failed call ([process])
/// so the UI can keep showing the current screen instead of going blank.
class ProcessError<PV> implements Exception {
  final String errorCode;
  final String message;
  final PV? process;

  const ProcessError({required this.errorCode, required this.message, this.process});

  @override
  String toString() => 'ProcessError($errorCode: $message)';
}
