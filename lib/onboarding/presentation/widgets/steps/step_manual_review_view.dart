import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bpm_framework/bpm_framework.dart';
import '../../../business_logic/onboarding_process_bloc.dart';
import '../../../data/models/onboarding_variables.dart';

/// Screen for the `manual_review` user task — only reached when the
/// exclusive gateway in `MockBpmEngine` routes a high `riskScore` here
/// instead of auto-approving.
class StepManualReviewView extends StatefulWidget {
  final Process<OnboardingVariables> process;
  final bool isBusy;

  const StepManualReviewView({super.key, required this.process, required this.isBusy});

  @override
  State<StepManualReviewView> createState() => _StepManualReviewViewState();
}

class _StepManualReviewViewState extends State<StepManualReviewView> {
  late final TextEditingController _reasonCtrl;
  bool _showReasonField = false;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  void _approve() {
    context.read<OnboardingProcessBloc>().add(const SubmitManualReviewDecision(approved: true));
  }

  void _reject() {
    if (!_showReasonField) {
      setState(() => _showReasonField = true);
      return;
    }
    context.read<OnboardingProcessBloc>().add(
          SubmitManualReviewDecision(approved: false, reason: _reasonCtrl.text.trim()),
        );
  }

  @override
  Widget build(BuildContext context) {
    final vars = widget.process.processVariables;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Revue manuelle', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              "Tâche « manual_review », atteinte uniquement lorsque le score de "
              "risque calculé par le moteur est élevé.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _SummaryRow(label: 'Nom du demandeur', value: vars.applicantName ?? '—'),
            _SummaryRow(label: 'Montant demandé', value: '${vars.requestedAmount ?? '—'}'),
            _SummaryRow(label: 'riskScore', value: '${vars.riskScore ?? '—'}'),
            const SizedBox(height: 20),
            if (_showReasonField) ...[
              TextField(
                controller: _reasonCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motif du refus',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: widget.isBusy ? null : _approve,
                    child: const Text('Approuver'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: widget.isBusy ? null : _reject,
                    child: Text(_showReasonField ? 'Confirmer le refus' : 'Refuser'),
                  ),
                ),
              ],
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
