import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bpm_framework/bpm_framework.dart';
import '../../../business_logic/onboarding_process_bloc.dart';
import '../../../data/models/onboarding_variables.dart';

/// Screen for a [TaskType.serviceTask] — a step with no human input.
///
/// The engine already computed everything it needs to (see
/// `MockBpmEngine._completeRiskScreening`); this view exists purely so the
/// "an automatic step just ran" moment is visible, then advances the
/// process itself once its simulated delay elapses. A real service task
/// calling out to an external system would follow the same shape: show
/// that work is happening, then continue once the response comes back.
class StepAutomaticProcessingView extends StatefulWidget {
  final Task<OnboardingVariables> task;

  const StepAutomaticProcessingView({super.key, required this.task});

  @override
  State<StepAutomaticProcessingView> createState() => _StepAutomaticProcessingViewState();
}

class _StepAutomaticProcessingViewState extends State<StepAutomaticProcessingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
  }

  Future<void> _advance() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    context
        .read<OnboardingProcessBloc>()
        .add(AdvanceAutomaticTask(taskDefinitionKey: widget.task.taskDefinitionKey));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(widget.task.name, style: Theme.of(context).textTheme.titleMedium),
            if (widget.task.description != null) ...[
              const SizedBox(height: 8),
              Text(widget.task.description!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
