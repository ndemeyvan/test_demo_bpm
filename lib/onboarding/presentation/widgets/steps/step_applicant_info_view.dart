import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bpm_framework/bpm_framework.dart';
import '../../../business_logic/onboarding_process_bloc.dart';
import '../../../data/models/onboarding_variables.dart';

/// Screen for the `applicant_info` user task.
class StepApplicantInfoView extends StatefulWidget {
  final Process<OnboardingVariables> process;
  final bool isBusy;

  const StepApplicantInfoView({super.key, required this.process, required this.isBusy});

  @override
  State<StepApplicantInfoView> createState() => _StepApplicantInfoViewState();
}

class _StepApplicantInfoViewState extends State<StepApplicantInfoView> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    final vars = widget.process.processVariables;
    _nameCtrl = TextEditingController(text: vars.applicantName ?? '');
    _emailCtrl = TextEditingController(text: vars.applicantEmail ?? '');
    _amountCtrl = TextEditingController(text: vars.requestedAmount?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = num.tryParse(_amountCtrl.text.trim());
    if (_nameCtrl.text.trim().isEmpty || amount == null || amount <= 0) return;

    context.read<OnboardingProcessBloc>().add(
          SubmitApplicantInfo(
            applicantName: _nameCtrl.text.trim(),
            applicantEmail: _emailCtrl.text.trim(),
            requestedAmount: amount,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Informations demandeur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              "Tâche « applicant_info » : ces données sont écrites dans les variables "
              "du process et transmises aux tâches suivantes.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom du demandeur', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant demandé',
                hintText: 'Ex : 200000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isBusy ? null : _submit,
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
