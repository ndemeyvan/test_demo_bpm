import 'package:flutter/material.dart';

import '../../../bpm_framework/bpm_framework.dart';
import '../../data/models/onboarding_variables.dart';

/// Shows the raw process variables carried by the current instance — the
/// same data a BPM engine's admin console ("Cockpit") would display.
/// Useful to *see* what each task read and wrote, which is otherwise
/// invisible once a screen only shows a form.
class ProcessVariablesInspector extends StatelessWidget {
  final Process<OnboardingVariables>? process;

  const ProcessVariablesInspector({super.key, this.process});

  @override
  Widget build(BuildContext context) {
    final vars = process?.processVariables;

    final entries = <MapEntry<String, String>>[
      MapEntry('processInstanceId', process?.processInstanceId ?? '—'),
      MapEntry(
        'activeTaskDefinitionKey',
        process?.activeTaskDefinitionKey ?? (process?.isEnded == true ? '(ended)' : '—'),
      ),
      MapEntry('applicantName', vars?.applicantName ?? '—'),
      MapEntry('applicantEmail', vars?.applicantEmail ?? '—'),
      MapEntry('requestedAmount', '${vars?.requestedAmount ?? '—'}'),
      MapEntry('documentUploaded', '${vars?.documentUploaded ?? '—'}'),
      MapEntry('riskScore', '${vars?.riskScore ?? '—'}'),
      MapEntry('reviewDecision', vars?.reviewDecision ?? '—'),
      MapEntry('autoApproved', '${vars?.autoApproved ?? '—'}'),
    ];

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: const Text('Variables du process', style: TextStyle(fontWeight: FontWeight.w600)),
          leading: Icon(Icons.data_object_rounded, color: Theme.of(context).colorScheme.primary),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [for (final entry in entries) _VariableRow(entry: entry)],
        ),
      ),
    );
  }
}

class _VariableRow extends StatelessWidget {
  final MapEntry<String, String> entry;

  const _VariableRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(entry.key, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
          Expanded(
            child: Text(
              entry.value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
