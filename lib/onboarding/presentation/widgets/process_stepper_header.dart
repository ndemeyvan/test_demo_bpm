import 'package:flutter/material.dart';

import '../../business_logic/onboarding_process_bloc.dart';
import '../../data/models/onboarding_task_keys.dart';

class _StepDef {
  final String key;
  final String label;

  const _StepDef(this.key, this.label);
}

enum _StepStatus { done, current, pending }

/// Purely visual progress indicator — it derives everything it shows from
/// `state.process.activeTaskDefinitionKey`, the same field
/// `OnboardingTaskSwitcher` uses to pick a screen, so the stepper and the
/// visible content can never disagree about where the process is.
class ProcessStepperHeader extends StatelessWidget {
  final OnboardingProcessState state;

  const ProcessStepperHeader({super.key, required this.state});

  static const _steps = [
    _StepDef(OnboardingTaskKeys.applicantInfo, 'Informations\ndemandeur'),
    _StepDef(OnboardingTaskKeys.uploadDocument, 'Pièce\njustificative'),
    _StepDef(OnboardingTaskKeys.manualReview, 'Revue\nmanuelle'),
  ];

  int _currentIndex() {
    final process = state.process;
    if (process == null) return 0;
    if (process.isEnded) return _steps.length;
    final index = _steps.indexWhere((s) => s.key == process.activeTaskDefinitionKey);
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentIndex = _currentIndex();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (var i = 0; i < _steps.length; i++) ...[
              _StepDot(
                index: i + 1,
                label: _steps[i].label,
                status: i < currentIndex
                    ? _StepStatus.done
                    : i == currentIndex
                        ? _StepStatus.current
                        : _StepStatus.pending,
              ),
              if (i != _steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    color: i < currentIndex ? colors.tertiary : colors.outlineVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final _StepStatus status;

  const _StepDot({required this.index, required this.label, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    switch (status) {
      case _StepStatus.done:
        bg = colors.tertiary;
        fg = colors.onTertiary;
      case _StepStatus.current:
        bg = colors.primary;
        fg = colors.onPrimary;
      case _StepStatus.pending:
        bg = colors.surfaceContainerHighest;
        fg = colors.onSurfaceVariant;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: bg,
          child: status == _StepStatus.done
              ? Icon(Icons.check_rounded, size: 16, color: fg)
              : Text('$index', style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 84,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}
