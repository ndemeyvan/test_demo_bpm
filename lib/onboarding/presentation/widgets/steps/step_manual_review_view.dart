import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bpm_framework/bpm_framework.dart';
import '../../../business_logic/onboarding_process_bloc.dart';
import '../../../data/models/onboarding_variables.dart';
import '../dynamic_form_view.dart';

/// Screen for the `manual_review` user task — only reached when the
/// `risk_screening` service task finds a high risk score.
///
/// Unlike the other user tasks, this one needs custom buttons (Approve /
/// Reject post different `outcome`s, not just "submit"), so it builds its
/// own action row instead of using the generic single-button footer — the
/// form *fields* themselves (just "reason" here) are still fully generic,
/// driven by the task's [FormDefinition] like everywhere else.
class StepManualReviewView extends StatelessWidget {
  final Task<OnboardingVariables> task;
  final bool isBusy;

  const StepManualReviewView({super.key, required this.task, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    final vars = task.processVariables;
    final form = task.form;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(task.name, style: Theme.of(context).textTheme.titleLarge),
            if (task.description != null) ...[
              const SizedBox(height: 4),
              Text(task.description!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 20),
            _SummaryRow(label: 'Nom du demandeur', value: vars.applicantName ?? '—'),
            _SummaryRow(label: 'Montant demandé', value: '${vars.requestedAmount ?? '—'}'),
            _SummaryRow(label: 'Canal', value: vars.channel ?? '—'),
            _SummaryRow(label: 'riskScore', value: '${vars.riskScore ?? '—'}'),
            const SizedBox(height: 20),
            if (form != null)
              DynamicFormView(
                form: form,
                isBusy: isBusy,
                actionsBuilder: (values, _) {
                  final reason = '${values['reason'] ?? ''}'.trim();
                  return [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: isBusy
                                ? null
                                : () => context.read<OnboardingProcessBloc>().add(
                                      SubmitTaskForm(
                                        taskDefinitionKey: task.taskDefinitionKey,
                                        outcome: 'approve',
                                        values: values,
                                      ),
                                    ),
                            child: const Text('Approuver'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.tonal(
                            // Extra rule layered on top of the generic form: a
                            // reason is required specifically to reject, even
                            // though the field itself isn't marked `required`
                            // at the form-definition level (approving needs no
                            // reason at all).
                            onPressed: isBusy || reason.isEmpty
                                ? null
                                : () => context.read<OnboardingProcessBloc>().add(
                                      SubmitTaskForm(
                                        taskDefinitionKey: task.taskDefinitionKey,
                                        outcome: 'reject',
                                        values: values,
                                      ),
                                    ),
                            child: const Text('Refuser'),
                          ),
                        ),
                      ],
                    ),
                  ];
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 160, child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
