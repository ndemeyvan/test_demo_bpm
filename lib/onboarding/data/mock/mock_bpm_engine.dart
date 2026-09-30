import '../../../bpm_framework/bpm_framework.dart';
import '../models/onboarding_task_keys.dart';
import '../models/onboarding_variables.dart';

/// ───────────────────────────────────────────────────────────────────────
/// MOCK BPM ENGINE — this is "the process" itself, written in plain Dart.
/// ───────────────────────────────────────────────────────────────────────
/// A real deployment would draw this as a BPMN diagram and deploy it to an
/// engine (Flowable/Activiti/Camunda); the app would only ever see its REST
/// API. This class stands in for that engine so the whole BPM flow can run
/// with no backend:
///
///   [start] ──▶ (applicant_info) ──▶ (upload_document) ──▶ `gateway`
///                  user task            user task          riskScore?
///                                                          ╱          ╲
///                                                  < 70  ╱              ╲  >= 70
///                                                       ▼                ▼
///                                                 [auto-approved]   (manual_review)
///                                                     [end]           user task
///                                                                   ╱        ╲
///                                                            approve          reject
///                                                              ▼                ▼
///                                                        [approved]       [rejected]
///                                                           [end]           [end]
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
    final instance = _EngineInstance(
      processInstanceId: id,
      currentTaskKey: OnboardingTaskKeys.applicantInfo,
      variables: const OnboardingVariables(),
    );
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

    // A real engine rejects a `complete` call against a task that is no
    // longer the active one (already completed elsewhere, or the screen was
    // left open too long). This is exactly why `OnboardingProcessBloc`
    // always resolves `taskInstanceId` from the *current* `activeTask`
    // right before calling `execTask`, instead of caching it.
    if (instance.currentTask?.id != taskInstanceId) {
      throw ProcessError<Process<OnboardingVariables>>(
        errorCode: 'com-task-0002',
        message: "Cette tâche n'est plus active — rafraîchissez le process.",
        process: instance.toProcess(),
      );
    }

    switch (instance.currentTaskKey) {
      case OnboardingTaskKeys.applicantInfo:
        _completeApplicantInfo(instance, body);
      case OnboardingTaskKeys.uploadDocument:
        _completeUploadDocument(instance, body);
      case OnboardingTaskKeys.manualReview:
        _completeManualReview(instance, outcome, body);
    }

    return instance.toProcess();
  }

  void _completeApplicantInfo(_EngineInstance instance, Map<String, dynamic> body) {
    final name = body['applicantName'] as String?;
    final email = body['applicantEmail'] as String?;
    final amount = body['requestedAmount'] as num?;

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
    );
    instance.moveTo(OnboardingTaskKeys.uploadDocument);
  }

  void _completeUploadDocument(_EngineInstance instance, Map<String, dynamic> body) {
    final documentName = body['documentName'] as String? ?? 'piece_identite.pdf';
    final amount = instance.variables.requestedAmount ?? 0;

    // Exclusive gateway: purely computed from process variables, no screen
    // is shown for it. The engine walks straight through to whichever task
    // (or end event) the condition selects.
    final riskScore = amount >= 500000 ? 78 : (amount >= 150000 ? 45 : 15);

    instance.variables = instance.variables.copyWith(
      documentUploaded: true,
      documentName: documentName,
      riskScore: riskScore,
    );

    if (riskScore >= 70) {
      instance.moveTo(OnboardingTaskKeys.manualReview);
    } else {
      instance.variables = instance.variables.copyWith(
        reviewDecision: 'approved',
        autoApproved: true,
      );
      instance.end();
    }
  }

  void _completeManualReview(_EngineInstance instance, String outcome, Map<String, dynamic> body) {
    final approved = outcome == 'approve';
    instance.variables = instance.variables.copyWith(
      reviewDecision: approved ? 'approved' : 'rejected',
      rejectionReason: approved ? null : (body['reason'] as String? ?? 'Non motivé'),
      autoApproved: false,
    );
    instance.end();
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

/// In-memory state for one running (or ended) process instance.
class _EngineInstance {
  _EngineInstance({
    required this.processInstanceId,
    required String currentTaskKey,
    required this.variables,
  }) : _currentTaskKey = currentTaskKey {
    _regenerateTask();
  }

  final String processInstanceId;
  OnboardingVariables variables;

  String? _currentTaskKey;
  Task<OnboardingVariables>? _currentTask;
  int _taskSequence = 0;

  String? get currentTaskKey => _currentTaskKey;

  Task<OnboardingVariables>? get currentTask => _currentTask;

  void moveTo(String taskKey) {
    _currentTaskKey = taskKey;
    _regenerateTask();
  }

  void end() {
    _currentTaskKey = null;
    _currentTask = null;
  }

  void _regenerateTask() {
    final key = _currentTaskKey;
    if (key == null) {
      _currentTask = null;
      return;
    }
    _currentTask = Task<OnboardingVariables>(
      id: '$processInstanceId-task-${++_taskSequence}',
      taskDefinitionKey: key,
      name: key,
      processInstanceId: processInstanceId,
      createTime: DateTime.now(),
      processVariables: variables,
    );
  }

  Process<OnboardingVariables> toProcess() {
    return Process<OnboardingVariables>(
      processInstanceId: processInstanceId,
      processDefinitionKey: 'merchant_onboarding_demo',
      isEnded: _currentTaskKey == null,
      startTime: DateTime.now(),
      processVariables: variables,
      activeTask: _currentTask == null ? const [] : [_currentTask!],
    );
  }
}
