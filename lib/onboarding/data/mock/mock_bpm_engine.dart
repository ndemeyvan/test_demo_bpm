import '../../../bpm_framework/bpm_framework.dart';
import '../models/onboarding_task_keys.dart';
import '../models/onboarding_variables.dart';

/// ───────────────────────────────────────────────────────────────────────
/// MOCK BPM ENGINE — this is "the process" itself, written in plain Dart.
/// ───────────────────────────────────────────────────────────────────────
/// A real deployment would draw this as a BPMN diagram and deploy it to an
/// engine (Flowable/Activiti/Camunda); the app would only ever see its REST
/// API. This class stands in for that engine so the whole BPM flow can run
/// with no backend. It deliberately covers several BPM patterns at once:
///
///   [start]
///      │
///      ▼
///   (applicant_info)  user task, FORM
///      │
///      ▼
///   ⟨parallel split⟩ ───────────────┐
///      │                            │
///      ▼                            ▼
///   (upload_id_document)      (upload_proof_of_address)   user tasks, FORM
///      │                            │
///      └──────────┬─────────────────┘
///                 ▼
///          ⟨parallel join⟩  — waits for BOTH branches
///                 │
///                 ▼
///          (risk_screening)   service task — automatic, no form
///                 │
///                 ▼
///          ⟨exclusive gateway⟩  riskScore?
///            ╱                          ╲
///        < 70                          >= 70
///          ▼                              ▼
///    [auto-approved]                (manual_review)   user task, FORM
///        [end]                        ╱          ╲
///                                approve          reject
///                                  ▼                  ▼
///                            [approved]          [rejected]
///                               [end]                [end]
///
/// Each public method mirrors one BPM REST endpoint:
///  - [start]        ~ `POST /process-instances`      (`ProcessRepository.startProcess`)
///  - [fetch]         ~ `GET  /process-instances/{id}`  (`ProcessRepository.fetchProcess`)
///  - [completeTask] ~ `POST /tasks/{id}/complete`     (`ProcessRepository.execTask`)
///
/// State lives only in memory ([_instances]) and a short `Future.delayed`
/// simulates network latency so loading states are actually visible.
class MockBpmEngine {
  MockBpmEngine._internal();

  static final MockBpmEngine instance = MockBpmEngine._internal();

  final Map<String, _EngineInstance> _instances = {};
  int _sequence = 0;

  Future<Process<OnboardingVariables>> start(Map<String, dynamic> body) async {
    await _simulateLatency();

    final id = 'onboarding-${++_sequence}';
    final instance = _EngineInstance(processInstanceId: id, variables: const OnboardingVariables());
    _instances[id] = instance;

    return instance.toProcess();
  }

  Future<Process<OnboardingVariables>> fetch(String processInstanceId) async {
    await _simulateLatency();
    return _require(processInstanceId).toProcess();
  }

  Future<Process<OnboardingVariables>> completeTask({
    required String processInstanceId,
    required String taskInstanceId,
    required String outcome,
    required Map<String, dynamic> body,
  }) async {
    await _simulateLatency();
    final instance = _require(processInstanceId);
    final task = instance.findTask(taskInstanceId);

    // A real engine rejects a `complete` call against a task that is no
    // longer active (already completed elsewhere, or the screen was left
    // open too long). This is exactly why `OnboardingProcessBloc` always
    // resolves `taskInstanceId` from the *current* `activeTask` right
    // before calling `execTask`, instead of caching it.
    if (task == null) {
      throw ProcessError<Process<OnboardingVariables>>(
        errorCode: 'com-task-0002',
        message: "Cette tâche n'est plus active — rafraîchissez le process.",
        process: instance.toProcess(),
      );
    }

    switch (task.taskDefinitionKey) {
      case OnboardingTaskKeys.applicantInfo:
        _completeApplicantInfo(instance, body);
      case OnboardingTaskKeys.uploadIdDocument:
        _completeUploadIdDocument(instance, body);
      case OnboardingTaskKeys.uploadProofOfAddress:
        _completeUploadProofOfAddress(instance, body);
      case OnboardingTaskKeys.riskScreening:
        _completeRiskScreening(instance);
      case OnboardingTaskKeys.manualReview:
        _completeManualReview(instance, outcome, body);
    }

    return instance.toProcess();
  }

  void _completeApplicantInfo(_EngineInstance instance, Map<String, dynamic> body) {
    final name = body['applicantName'] as String?;
    final email = body['applicantEmail'] as String?;
    final amount = _toNum(body['requestedAmount']);
    final channel = body['channel'] as String?;

    if (name == null || name.trim().isEmpty || amount == null || amount <= 0) {
      // Simulates a BPMN form-property validation failure returned by the
      // engine before it lets the token move past the task boundary.
      throw ProcessError<Process<OnboardingVariables>>(
        errorCode: 'form-validation',
        message: 'Le nom et le montant demandé sont obligatoires.',
        process: instance.toProcess(),
      );
    }

    instance.variables = instance.variables.copyWith(
      applicantName: name,
      applicantEmail: email,
      requestedAmount: amount,
      channel: channel,
    );

    // Parallel split (AND-fork): both document uploads become active at
    // the same time — `process.activeTask` now holds two entries.
    instance.completeOne(
      OnboardingTaskKeys.applicantInfo,
      () => {OnboardingTaskKeys.uploadIdDocument, OnboardingTaskKeys.uploadProofOfAddress},
    );
  }

  void _completeUploadIdDocument(_EngineInstance instance, Map<String, dynamic> body) {
    final name = body['idDocument'] as String?;
    if (name == null) {
      throw ProcessError<Process<OnboardingVariables>>(
        errorCode: 'form-validation',
        message: "La pièce d'identité est obligatoire.",
        process: instance.toProcess(),
      );
    }
    instance.variables = instance.variables.copyWith(idDocumentUploaded: true, idDocumentName: name);

    // AND-join: this only actually advances the process once the sibling
    // branch (`upload_proof_of_address`) has also completed — see
    // `_EngineInstance.completeOne`.
    instance.completeOne(OnboardingTaskKeys.uploadIdDocument, () => {OnboardingTaskKeys.riskScreening});
  }

  void _completeUploadProofOfAddress(_EngineInstance instance, Map<String, dynamic> body) {
    final name = body['proofOfAddress'] as String?;
    if (name == null) {
      throw ProcessError<Process<OnboardingVariables>>(
        errorCode: 'form-validation',
        message: 'Le justificatif de domicile est obligatoire.',
        process: instance.toProcess(),
      );
    }
    instance.variables = instance.variables.copyWith(proofOfAddressUploaded: true, proofOfAddressName: name);
    instance.completeOne(OnboardingTaskKeys.uploadProofOfAddress, () => {OnboardingTaskKeys.riskScreening});
  }

  void _completeRiskScreening(_EngineInstance instance) {
    final amount = instance.variables.requestedAmount ?? 0;
    final isOnline = instance.variables.channel == 'online';

    // A purely computed condition, exactly like a real risk-scoring
    // service a BPM process would call out to. No screen is shown for
    // this step; the *task itself* (`risk_screening`) is what's visible —
    // as an automatic "processing" screen — not this calculation.
    var riskScore = amount >= 500000 ? 78 : (amount >= 150000 ? 45 : 15);
    if (isOnline) riskScore += 10;

    instance.variables = instance.variables.copyWith(riskScore: riskScore);

    instance.completeOne(OnboardingTaskKeys.riskScreening, () {
      if (riskScore >= 70) return {OnboardingTaskKeys.manualReview};
      instance.variables = instance.variables.copyWith(reviewDecision: 'approved', autoApproved: true);
      return const {}; // end event: auto-approved
    });
  }

  void _completeManualReview(_EngineInstance instance, String outcome, Map<String, dynamic> body) {
    final approved = outcome == 'approve';
    instance.variables = instance.variables.copyWith(
      reviewDecision: approved ? 'approved' : 'rejected',
      rejectionReason: approved ? null : (body['reason'] as String? ?? 'Non motivé'),
      autoApproved: false,
    );
    instance.completeOne(OnboardingTaskKeys.manualReview, () => const {}); // end event
  }

  _EngineInstance _require(String processInstanceId) {
    final instance = _instances[processInstanceId];
    if (instance == null) {
      throw ProcessError<Process<OnboardingVariables>>(
        errorCode: 'process-not-found',
        message: 'Instance de process inconnue : $processInstanceId',
      );
    }
    return instance;
  }

  Future<void> _simulateLatency() => Future.delayed(const Duration(milliseconds: 550));
}

/// In-memory state for one running (or ended) process instance. Supports
/// more than one simultaneously active task, which is what a parallel
/// gateway needs.
class _EngineInstance {
  _EngineInstance({required this.processInstanceId, required this.variables}) {
    _activate({OnboardingTaskKeys.applicantInfo});
  }

  final String processInstanceId;
  OnboardingVariables variables;

  Set<String> _activeKeys = {};
  List<Task<OnboardingVariables>> _currentTasks = [];

  /// A stable id per active task key — reassigning a *new* id every time
  /// `_currentTasks` is rebuilt would make a still-pending sibling task
  /// (the other half of a parallel split) look stale to the app the
  /// moment its sibling completes.
  final Map<String, String> _taskIds = {};
  int _taskSequence = 0;

  bool get isEnded => _activeKeys.isEmpty;

  Task<OnboardingVariables>? findTask(String taskInstanceId) {
    for (final task in _currentTasks) {
      if (task.id == taskInstanceId) return task;
    }
    return null;
  }

  /// Completes [finishedKey]. If other keys are still active (a pending
  /// sibling from a parallel split), the process simply waits — the
  /// AND-join. Once every active branch is done, [onAllDone] decides what
  /// comes next (a single follow-up task, several for another parallel
  /// split, or none at all for an end event).
  void completeOne(String finishedKey, Set<String> Function() onAllDone) {
    _activeKeys = Set.of(_activeKeys)..remove(finishedKey);
    _taskIds.remove(finishedKey);
    if (_activeKeys.isEmpty) {
      _activate(onAllDone());
    } else {
      _syncTasks();
    }
  }

  void _activate(Set<String> keys) {
    _activeKeys = keys;
    _syncTasks();
  }

  void _syncTasks() {
    _currentTasks = [for (final key in _activeKeys) _buildTask(key)];
  }

  Task<OnboardingVariables> _buildTask(String key) {
    final id = _taskIds.putIfAbsent(key, () => '$processInstanceId-task-${++_taskSequence}');
    return Task<OnboardingVariables>(
      id: id,
      taskDefinitionKey: key,
      name: _taskName(key),
      description: _taskDescription(key),
      processInstanceId: processInstanceId,
      createTime: DateTime.now(),
      processVariables: variables,
      type: key == OnboardingTaskKeys.riskScreening ? TaskType.serviceTask : TaskType.userTask,
      form: _formFor(key),
    );
  }

  Process<OnboardingVariables> toProcess() {
    return Process<OnboardingVariables>(
      processInstanceId: processInstanceId,
      processDefinitionKey: 'merchant_onboarding_demo',
      isEnded: isEnded,
      startTime: DateTime.now(),
      processVariables: variables,
      activeTask: _currentTasks,
    );
  }
}

String _taskName(String key) => switch (key) {
      OnboardingTaskKeys.applicantInfo => 'Informations demandeur',
      OnboardingTaskKeys.uploadIdDocument => "Pièce d'identité",
      OnboardingTaskKeys.uploadProofOfAddress => 'Justificatif de domicile',
      OnboardingTaskKeys.riskScreening => 'Vérification automatique du risque',
      OnboardingTaskKeys.manualReview => 'Revue manuelle',
      _ => key,
    };

String? _taskDescription(String key) => switch (key) {
      OnboardingTaskKeys.applicantInfo =>
        'Tâche « applicant_info » : ces données sont écrites dans les variables du process.',
      OnboardingTaskKeys.uploadIdDocument =>
        'Tâche « upload_id_document » — une des deux branches parallèles ouvertes après « applicant_info ».',
      OnboardingTaskKeys.uploadProofOfAddress =>
        "Tâche « upload_proof_of_address » — l'autre branche parallèle. Le process attend que les "
            'deux soient complétées (jointure) avant de continuer.',
      OnboardingTaskKeys.riskScreening =>
        'Tâche automatique (service task) : aucune interaction humaine, le moteur calcule le score '
            'de risque lui-même.',
      OnboardingTaskKeys.manualReview => 'Tâche « manual_review », atteinte uniquement lorsque le '
          'score de risque calculé est élevé.',
      _ => null,
    };

FormDefinition? _formFor(String key) => switch (key) {
      OnboardingTaskKeys.applicantInfo => const FormDefinition(
          fields: [
            FormFieldDef(
              key: 'applicantName',
              label: 'Nom du demandeur',
              type: FormFieldType.text,
              required: true,
            ),
            FormFieldDef(
              key: 'applicantEmail',
              label: 'E-mail',
              type: FormFieldType.email,
              required: true,
            ),
            FormFieldDef(
              key: 'requestedAmount',
              label: 'Montant demandé',
              type: FormFieldType.number,
              required: true,
              hint: 'Ex : 200000',
            ),
            FormFieldDef(
              key: 'channel',
              label: 'Canal de la demande',
              type: FormFieldType.select,
              required: true,
              options: [
                FormFieldOption(value: 'online', label: 'En ligne'),
                FormFieldOption(value: 'agence', label: 'En agence'),
              ],
            ),
          ],
        ),
      OnboardingTaskKeys.uploadIdDocument => const FormDefinition(
          fields: [
            FormFieldDef(
              key: 'idDocument',
              label: "Pièce d'identité",
              type: FormFieldType.document,
              required: true,
            ),
          ],
        ),
      OnboardingTaskKeys.uploadProofOfAddress => const FormDefinition(
          fields: [
            FormFieldDef(
              key: 'proofOfAddress',
              label: 'Justificatif de domicile',
              type: FormFieldType.document,
              required: true,
            ),
          ],
        ),
      OnboardingTaskKeys.manualReview => const FormDefinition(
          fields: [
            FormFieldDef(
              key: 'reason',
              label: 'Motif (obligatoire en cas de refus)',
              type: FormFieldType.textarea,
            ),
          ],
        ),
      _ => null, // service tasks have no form — nothing to ask a human.
    };

num? _toNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse('$value');
}
