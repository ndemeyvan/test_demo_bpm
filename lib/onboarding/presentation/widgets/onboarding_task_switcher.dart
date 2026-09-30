import 'package:flutter/material.dart';

import '../../business_logic/onboarding_process_bloc.dart';
import '../../data/models/onboarding_task_keys.dart';
import 'process_error_view.dart';
import 'process_loading_view.dart';
import 'steps/step_applicant_info_view.dart';
import 'steps/step_manual_review_view.dart';
import 'steps/step_result_view.dart';
import 'steps/step_upload_document_view.dart';

/// This is the "screen router" of the BPM demo.
///
/// It reads `process.activeTaskDefinitionKey` — the one field the BPM
/// engine uses to say "here is the task a human must complete next" — and
/// renders the screen that matches it. Add a task to the process
/// definition, add a `case` here: that is the entire integration surface
/// between a new BPMN task and its Flutter screen.
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

    final isBusy = state is OnboardingProcessLoading;

    return switch (process.activeTaskDefinitionKey) {
      OnboardingTaskKeys.applicantInfo =>
        StepApplicantInfoView(process: process, isBusy: isBusy),
      OnboardingTaskKeys.uploadDocument =>
        StepUploadDocumentView(process: process, isBusy: isBusy),
      OnboardingTaskKeys.manualReview =>
        StepManualReviewView(process: process, isBusy: isBusy),
      _ => const ProcessLoadingView(),
    };
  }
}
