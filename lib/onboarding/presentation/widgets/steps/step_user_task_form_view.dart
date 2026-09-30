import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bpm_framework/bpm_framework.dart';
import '../../../business_logic/onboarding_process_bloc.dart';
import '../../../data/models/onboarding_variables.dart';
import '../dynamic_form_view.dart';

/// Generic screen for any single-button user task that carries a
/// [FormDefinition] — `applicant_info`, `upload_id_document` and
/// `upload_proof_of_address` all render through this one widget. Nothing
/// here is specific to any of those three tasks: title, description and
/// fields all come straight from the [task] the engine handed over.
class StepUserTaskFormView extends StatelessWidget {
  final Task<OnboardingVariables> task;
  final bool isBusy;

  const StepUserTaskFormView({super.key, required this.task, required this.isBusy});

  Map<String, dynamic> _initialValues() {
    final vars = task.processVariables;
    return {
      'applicantName': vars.applicantName,
      'applicantEmail': vars.applicantEmail,
      'requestedAmount': vars.requestedAmount,
      'channel': vars.channel,
      'idDocument': vars.idDocumentName,
      'proofOfAddress': vars.proofOfAddressName,
    };
  }

  @override
  Widget build(BuildContext context) {
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
            if (form != null)
              DynamicFormView(
                form: form,
                initialValues: _initialValues(),
                isBusy: isBusy,
                actionsBuilder: (values, isValid) => [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isBusy || !isValid
                          ? null
                          : () => context.read<OnboardingProcessBloc>().add(
                                SubmitTaskForm(
                                  taskDefinitionKey: task.taskDefinitionKey,
                                  outcome: 'submit',
                                  values: values,
                                ),
                              ),
                      child: const Text('Continuer'),
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
