/// Base class for the data a BPM process instance carries.
///
/// A BPM engine calls this the "process variables": a bag of data that
/// travels with the instance from task to task. Every concrete process
/// defines its own subclass listing the fields it actually needs — see
/// `onboarding/data/models/onboarding_variables.dart`.
abstract class Variable {
  const Variable();
}
