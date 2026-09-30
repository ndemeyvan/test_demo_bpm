/// A tiny, self-contained BPM client library.
///
/// This is a trimmed-down illustration of the shape a real BPM client
/// package (e.g. a Flowable/Activiti REST client) tends to have:
/// `Process` / `Task` / `Variable` model the engine's vocabulary,
/// `BpmService` is the swappable transport, and `ProcessRepository` is the
/// stable surface the rest of the app is built against. See
/// `lib/onboarding/data/mock` for the mocked engine plugged in here.
library;

export 'bpm_service.dart';
export 'process.dart';
export 'process_error.dart';
export 'process_repository.dart';
export 'process_state.dart';
export 'task.dart';
export 'variable.dart';
