import 'package:flutter/material.dart';

import '../../../bpm_framework/bpm_framework.dart';
import '../../business_logic/onboarding_process_bloc.dart';
import '../../data/models/onboarding_task_keys.dart';
import '../../data/models/onboarding_variables.dart';
import 'process_error_view.dart';
import 'process_loading_view.dart';
import 'steps/step_automatic_processing_view.dart';
import 'steps/step_manual_review_view.dart';
import 'steps/step_result_view.dart';
import 'steps/step_user_task_form_view.dart';

/// This is the "screen router" of the BPM demo.
///
/// It reads `process.activeTask` — the list the BPM engine uses to say
/// "here is what a human (or the system itself) must do next" — and
/// renders the matching screen(s). Three shapes are handled:
///  - **one user task** with a form → the generic `StepUserTaskFormView`
///    (or the bespoke `StepManualReviewView` for the one task that needs
///    custom buttons);
///  - **more than one active task** → a parallel gateway: every branch
///    gets its own card, completed independently;
///  - **one service task** → `StepAutomaticProcessingView`, which advances
///    the process itself once its delay elapses.
class OnboardingTaskSwitcher extends StatelessWidget {
  final OnboardingProcessState state;

  const OnboardingTaskSwitcher({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final process = state.process;

    if (process == null) {
      if (state case OnboardingProcessFailure(:final message)) {
        return ProcessErrorView(message: message ?? '');
      }
      return const ProcessLoadingView();
    }

    if (process.isEnded) {
      return StepResultView(process: process);
    }

    final tasks = process.activeTask;
    if (tasks.isEmpty) {
      return const ProcessLoadingView();
    }

    final isBusy = state is OnboardingProcessLoading;

    if (tasks.length == 1) {
      return _buildTask(tasks.first, isBusy);
    }

    // Parallel gateway: several tasks are active at once — each is
    // completed independently, and the engine only moves on once all of
    // them are done (the AND-join, see `MockBpmEngine.completeOne`).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final task in tasks) ...[
          _buildTask(task, isBusy),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTask(Task<OnboardingVariables> task, bool isBusy) {
    if (task.type == TaskType.serviceTask) {
      return StepAutomaticProcessingView(task: task);
    }
    return switch (task.taskDefinitionKey) {
      OnboardingTaskKeys.manualReview => StepManualReviewView(task: task, isBusy: isBusy),
      _ => StepUserTaskFormView(task: task, isBusy: isBusy),
    };
  }
}
