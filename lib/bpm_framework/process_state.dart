import 'package:equatable/equatable.dart';

import 'process.dart';
import 'variable.dart';

/// Base class for a BPM bloc's events — kept minimal so any state emitted
/// is comparable via [Equatable].
abstract class ProcessEvent extends Equatable {
  const ProcessEvent();

  @override
  List<Object?> get props => [];
}

/// Base class for a BPM bloc's state: every state carries the last known
/// [process] (so the UI never has to fall back to "nothing" between
/// actions) and an optional [message] for the error states.
abstract class ProcessState<PV extends Variable> extends Equatable {
  final Process<PV>? process;
  final String? message;

  const ProcessState({this.process, this.message});

  @override
  List<Object?> get props => [process, message];
}
