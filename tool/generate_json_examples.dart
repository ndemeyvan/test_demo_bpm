// Regenerates docs/json-examples/*.json from the actual code — run it
// again after touching MockBpmEngine or the models so the examples never
// drift from what the app really produces:
//
//   dart run tool/generate_json_examples.dart
//
// These are the exact payloads `MockBpmService` encodes/decodes at each
// step of the demo process — real output, not hand-typed JSON.
import 'dart:convert';
import 'dart:io';

import 'package:test_demo_bpm/bpm_framework/bpm_framework.dart';
import 'package:test_demo_bpm/onboarding/data/models/onboarding_task_keys.dart';
import 'package:test_demo_bpm/onboarding/data/models/onboarding_variables.dart';
import 'package:test_demo_bpm/onboarding/data/repositories/onboarding_process_repository.dart';

const _encoder = JsonEncoder.withIndent('  ');

Future<void> main() async {
  final dir = Directory('docs/json-examples')..createSync(recursive: true);

  print('Scénario 1 — montant faible, auto-approuvé :');
  await _lowAmountScenario(dir);

  print('Scénario 2 — montant élevé, revue manuelle puis refus :');
  await _highAmountScenario(dir);

  print('Scénario 3 — erreurs renvoyées par le moteur :');
  await _errorScenarios(dir);

  print('\nExemples régénérés dans ${dir.path}/');
}

void _write(Directory dir, String filename, Process<OnboardingVariables> process) {
  final json = _encoder.convert(process.toJson((v) => v.toJson()));
  File('${dir.path}/$filename').writeAsStringSync('$json\n');
  print('  $filename');
}

void _writeError(Directory dir, String filename, ProcessError<Process<OnboardingVariables>> error) {
  final json = _encoder.convert({'errorCode': error.errorCode, 'message': error.message});
  File('${dir.path}/$filename').writeAsStringSync('$json\n');
  print('  $filename');
}

Future<void> _lowAmountScenario(Directory dir) async {
  final repo = OnboardingProcessRepository();

  var process = await repo.startProcess();
  _write(dir, '01-start.json', process);

  process = await repo.execTask(
    processInstanceId: process.processInstanceId,
    taskInstanceId: process.activeTask.first.id,
    outcome: 'submit',
    body: {
      'applicantName': 'Alice Dupont',
      'applicantEmail': 'alice.dupont@example.com',
      'requestedAmount': 50000,
      'channel': 'agence',
    },
  );
  _write(dir, '02-parallel-split-two-active-tasks.json', process);

  final idTask =
      process.activeTask.firstWhere((t) => t.taskDefinitionKey == OnboardingTaskKeys.uploadIdDocument);
  process = await repo.execTask(
    processInstanceId: process.processInstanceId,
    taskInstanceId: idTask.id,
    outcome: 'submit',
    body: {'idDocument': 'cni_alice.pdf'},
  );
  _write(dir, '03-one-branch-done-join-still-pending.json', process);

  process = await repo.execTask(
    processInstanceId: process.processInstanceId,
    taskInstanceId: process.activeTask.first.id,
    outcome: 'submit',
    body: {'proofOfAddress': 'facture_edf_alice.pdf'},
  );
  _write(dir, '04-join-complete-risk-screening-service-task.json', process);

  process = await repo.execTask(
    processInstanceId: process.processInstanceId,
    taskInstanceId: process.activeTask.first.id,
    outcome: 'auto',
    body: const {},
  );
  _write(dir, '05-auto-approved-end.json', process);
}

Future<void> _highAmountScenario(Directory dir) async {
  final repo = OnboardingProcessRepository();

  var process = await repo.startProcess();
  process = await repo.execTask(
    processInstanceId: process.processInstanceId,
    taskInstanceId: process.activeTask.first.id,
    outcome: 'submit',
    body: {
      'applicantName': 'Bernard Kouassi',
      'applicantEmail': 'bernard.kouassi@example.com',
      'requestedAmount': 900000,
      'channel': 'online',
    },
  );

  for (final key in [OnboardingTaskKeys.uploadIdDocument, OnboardingTaskKeys.uploadProofOfAddress]) {
    final task = process.activeTask.firstWhere((t) => t.taskDefinitionKey == key);
    process = await repo.execTask(
      processInstanceId: process.processInstanceId,
      taskInstanceId: task.id,
      outcome: 'submit',
      body: {'idDocument': 'cni_bernard.pdf', 'proofOfAddress': 'facture_bernard.pdf'},
    );
  }

  process = await repo.execTask(
    processInstanceId: process.processInstanceId,
    taskInstanceId: process.activeTask.first.id,
    outcome: 'auto',
    body: const {},
  );
  _write(dir, '06-manual-review-required.json', process);

  process = await repo.execTask(
    processInstanceId: process.processInstanceId,
    taskInstanceId: process.activeTask.first.id,
    outcome: 'reject',
    body: {'reason': 'Justificatif de domicile illisible'},
  );
  _write(dir, '07-rejected-end.json', process);
}

Future<void> _errorScenarios(Directory dir) async {
  final repo = OnboardingProcessRepository();
  final started = await repo.startProcess();

  try {
    await repo.execTask(
      processInstanceId: started.processInstanceId,
      taskInstanceId: started.activeTask.first.id,
      outcome: 'submit',
      body: {'applicantName': '', 'requestedAmount': 0},
    );
  } on ProcessError<Process<OnboardingVariables>> catch (e) {
    _writeError(dir, '08-form-validation-error.json', e);
  }

  try {
    await repo.execTask(
      processInstanceId: started.processInstanceId,
      taskInstanceId: 'not-the-active-task-id',
      outcome: 'submit',
      body: {'applicantName': 'X', 'requestedAmount': 1},
    );
  } on ProcessError<Process<OnboardingVariables>> catch (e) {
    _writeError(dir, '09-stale-task-error.json', e);
  }
}
