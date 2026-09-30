import 'dart:convert';

import '../../../bpm_framework/bpm_framework.dart';
import '../models/onboarding_variables.dart';
import 'mock_bpm_engine.dart';

/// Implements the [BpmService] contract using [MockBpmEngine] instead of a
/// network call — but, unlike a naive mock, it still goes through **real
/// JSON**: every response is `jsonEncode`d exactly as it would travel over
/// HTTP, then `jsonDecode`d and parsed back with `Process.fromJson`, the
/// same two steps a Dio/http-based `BpmService` performs on a real
/// response body.
///
/// [ProcessRepository] only ever talks to a [BpmService] — it never knows
/// whether that service is real or mocked. Swapping this class in for an
/// HTTP-backed implementation is therefore the *only* change needed to run
/// an entire BPM screen without a backend: nothing above the repository
/// (the bloc, the screens, the screen-switching logic) has to know, and
/// nothing about the JSON shape changes either.
class MockBpmService implements BpmService<OnboardingVariables> {
  /// The last JSON payload that crossed the mock "wire", pretty-printed —
  /// purely for `ProcessVariablesInspector` to display; a real app has no
  /// equivalent of this (the JSON just lives inside the HTTP client).
  static String lastWireJson = '';

  @override
  Future<Process<OnboardingVariables>> startProcess(Map<String, dynamic> body) async {
    try {
      return _throughWire(await MockBpmEngine.instance.start(body));
    } on ProcessError<Process<OnboardingVariables>> catch (e) {
      throw _throughWireError(e);
    }
  }

  @override
  Future<Process<OnboardingVariables>> fetchProcess(String processInstanceId) async {
    try {
      return _throughWire(await MockBpmEngine.instance.fetch(processInstanceId));
    } on ProcessError<Process<OnboardingVariables>> catch (e) {
      throw _throughWireError(e);
    }
  }

  @override
  Future<Process<OnboardingVariables>> completeTask({
    required String processInstanceId,
    required String taskInstanceId,
    required String outcome,
    required Map<String, dynamic> body,
  }) async {
    try {
      final process = await MockBpmEngine.instance.completeTask(
        processInstanceId: processInstanceId,
        taskInstanceId: taskInstanceId,
        outcome: outcome,
        body: body,
      );
      return _throughWire(process);
    } on ProcessError<Process<OnboardingVariables>> catch (e) {
      throw _throughWireError(e);
    }
  }

  /// Encodes [process] to a JSON string — what a server would actually
  /// send as the HTTP response body — then decodes and parses it straight
  /// back. Nothing above this method ever sees anything but typed Dart
  /// objects; this is the one place the "data source" is genuinely JSON.
  Process<OnboardingVariables> _throughWire(Process<OnboardingVariables> process) {
    final wireJson = jsonEncode(process.toJson((vars) => vars.toJson()));
    lastWireJson = const JsonEncoder.withIndent('  ').convert(jsonDecode(wireJson));

    final decoded = jsonDecode(wireJson) as Map<String, dynamic>;
    return Process.fromJson<OnboardingVariables>(decoded, OnboardingVariables.fromJson);
  }

  ProcessError<Process<OnboardingVariables>> _throughWireError(
    ProcessError<Process<OnboardingVariables>> error,
  ) {
    return ProcessError<Process<OnboardingVariables>>(
      errorCode: error.errorCode,
      message: error.message,
      process: error.process == null ? null : _throughWire(error.process!),
    );
  }
}
