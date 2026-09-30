import 'package:flutter_test/flutter_test.dart';
import 'package:test_demo_bpm/bpm_framework/bpm_framework.dart';
import 'package:test_demo_bpm/onboarding/data/models/onboarding_task_keys.dart';
import 'package:test_demo_bpm/onboarding/data/models/onboarding_variables.dart';
import 'package:test_demo_bpm/onboarding/data/repositories/onboarding_process_repository.dart';

/// Exercises `MockBpmEngine` through the exact same door the app uses
/// (`ProcessRepository.startProcess` / `execTask`), without going through
/// the bloc or any widget. `OnboardingProcessBloc` itself only adds thin
/// event → repository-call glue on top of this and is covered by
/// `flutter analyze`'s type checking; this test is about the BPM logic —
/// forms, the parallel split/join, the automatic task and the exclusive
/// gateway — actually working end to end.
void main() {
  group('OnboardingProcessRepository + MockBpmEngine (no backend involved)', () {
    test('a low requested amount is auto-approved after the parallel uploads join', () async {
      final repo = OnboardingProcessRepository();

      var process = await repo.startProcess();
      expect(process.activeTask, hasLength(1));
      expect(process.activeTaskDefinitionKey, OnboardingTaskKeys.applicantInfo);

      process = await repo.execTask(
        processInstanceId: process.processInstanceId,
        taskInstanceId: process.activeTask.first.id,
        outcome: 'submit',
        body: {
          'applicantName': 'Alice',
          'applicantEmail': 'alice@example.com',
          'requestedAmount': 50000,
          'channel': 'agence',
        },
      );

      // Parallel split: both document uploads are active at once.
      expect(process.activeTask, hasLength(2));
      final activeKeys = process.activeTask.map((t) => t.taskDefinitionKey).toSet();
      expect(
        activeKeys,
        {OnboardingTaskKeys.uploadIdDocument, OnboardingTaskKeys.uploadProofOfAddress},
      );

      final idTask = process.activeTask.firstWhere(
        (t) => t.taskDefinitionKey == OnboardingTaskKeys.uploadIdDocument,
      );
      process = await repo.execTask(
        processInstanceId: process.processInstanceId,
        taskInstanceId: idTask.id,
        outcome: 'submit',
        body: {'idDocument': 'id.pdf'},
      );

      // AND-join hasn't fired yet: the sibling branch is still pending, on
      // the exact same task id it started with.
      expect(process.activeTask, hasLength(1));
      expect(process.activeTaskDefinitionKey, OnboardingTaskKeys.uploadProofOfAddress);
      final proofTask = process.activeTask.first;

      process = await repo.execTask(
        processInstanceId: process.processInstanceId,
        taskInstanceId: proofTask.id,
        outcome: 'submit',
        body: {'proofOfAddress': 'proof.pdf'},
      );

      // Both branches done: the join fired, moving on to the automatic
      // risk-screening service task.
      expect(process.activeTask, hasLength(1));
      expect(process.activeTaskDefinitionKey, OnboardingTaskKeys.riskScreening);
      expect(process.activeTask.first.type, TaskType.serviceTask);
      expect(process.activeTask.first.form, isNull);

      // The UI would auto-advance this one after a delay; the test does it
      // directly, the same call `AdvanceAutomaticTask` makes.
      process = await repo.execTask(
        processInstanceId: process.processInstanceId,
        taskInstanceId: process.activeTask.first.id,
        outcome: 'auto',
        body: const {},
      );

      expect(process.isEnded, isTrue);
      expect(process.isApproved, isTrue);
      expect(process.processVariables.autoApproved, isTrue);
      expect(process.processVariables.riskScore, lessThan(70));
    });

    test('a high requested amount routes to manual_review, which can reject', () async {
      final repo = OnboardingProcessRepository();

      var process = await repo.startProcess();
      process = await repo.execTask(
        processInstanceId: process.processInstanceId,
        taskInstanceId: process.activeTask.first.id,
        outcome: 'submit',
        body: {
          'applicantName': 'Bob',
          'applicantEmail': 'bob@example.com',
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
          body: {'idDocument': 'id.pdf', 'proofOfAddress': 'proof.pdf'},
        );
      }

      expect(process.activeTaskDefinitionKey, OnboardingTaskKeys.riskScreening);

      process = await repo.execTask(
        processInstanceId: process.processInstanceId,
        taskInstanceId: process.activeTask.first.id,
        outcome: 'auto',
        body: const {},
      );

      expect(process.isEnded, isFalse);
      expect(process.activeTaskDefinitionKey, OnboardingTaskKeys.manualReview);
      expect(process.processVariables.riskScore, greaterThanOrEqualTo(70));

      process = await repo.execTask(
        processInstanceId: process.processInstanceId,
        taskInstanceId: process.activeTask.first.id,
        outcome: 'reject',
        body: {'reason': 'Document suspect'},
      );

      expect(process.isEnded, isTrue);
      expect(process.isRejected, isTrue);
      expect(process.processVariables.rejectionReason, 'Document suspect');
    });

    test('an incomplete applicant_info submission throws a ProcessError without advancing', () async {
      final repo = OnboardingProcessRepository();
      final started = await repo.startProcess();

      expect(
        () => repo.execTask(
          processInstanceId: started.processInstanceId,
          taskInstanceId: started.activeTask.first.id,
          outcome: 'submit',
          body: {'applicantName': '', 'requestedAmount': 0},
        ),
        throwsA(isA<ProcessError<Process<OnboardingVariables>>>()),
      );
    });

    test('completing a task with a stale taskInstanceId is rejected (com-task-0002)', () async {
      final repo = OnboardingProcessRepository();
      final started = await repo.startProcess();

      try {
        await repo.execTask(
          processInstanceId: started.processInstanceId,
          taskInstanceId: 'not-the-active-task-id',
          outcome: 'submit',
          body: {'applicantName': 'Alice', 'requestedAmount': 1000},
        );
        fail('expected a ProcessError');
      } on ProcessError<Process<OnboardingVariables>> catch (e) {
        expect(e.errorCode, 'com-task-0002');
      }
    });
  });
}
