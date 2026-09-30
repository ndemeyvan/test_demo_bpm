import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bpm_framework/bpm_framework.dart';
import '../../../business_logic/onboarding_process_bloc.dart';
import '../../../data/models/onboarding_variables.dart';

/// Screen for the `upload_document` user task.
class StepUploadDocumentView extends StatefulWidget {
  final Process<OnboardingVariables> process;
  final bool isBusy;

  const StepUploadDocumentView({super.key, required this.process, required this.isBusy});

  @override
  State<StepUploadDocumentView> createState() => _StepUploadDocumentViewState();
}

class _StepUploadDocumentViewState extends State<StepUploadDocumentView> {
  String? _pickedFileName;

  void _pickFile() {
    // No real file_picker dependency here — the point of this demo is the
    // BPM flow, not file I/O, so "picking" a file is simulated instantly.
    setState(() => _pickedFileName = 'piece_identite.pdf');
  }

  void _submit() {
    if (_pickedFileName == null) return;
    context
        .read<OnboardingProcessBloc>()
        .add(SubmitDocumentUpload(documentName: _pickedFileName!));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final uploaded = _pickedFileName != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pièce justificative', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              "Tâche « upload_document ». Une fois complétée, le moteur calcule un "
              "score de risque et bifurque automatiquement (passerelle exclusive) "
              "vers une approbation automatique ou une revue manuelle — sans écran "
              "intermédiaire.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: colors.outline),
                  borderRadius: BorderRadius.circular(12),
                  color: uploaded ? colors.secondaryContainer : colors.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    Icon(
                      uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                      color: uploaded ? colors.secondary : colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_pickedFileName ?? 'Sélectionner un document'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isBusy || !uploaded ? null : _submit,
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
