import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bpm_framework/bpm_framework.dart';
import '../../../business_logic/onboarding_process_bloc.dart';
import '../../../data/models/onboarding_variables.dart';

/// Terminal screen: the process reached an end event (`process.isEnded`),
/// so there is no `activeTask` left to switch on — the outcome instead
/// comes straight from the process variables (`reviewDecision`).
class StepResultView extends StatelessWidget {
  final Process<OnboardingVariables> process;

  const StepResultView({super.key, required this.process});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final approved = process.isApproved;
    final vars = process.processVariables;

    return Card(
      color: approved ? colors.tertiaryContainer : colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              approved ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 48,
              color: approved ? colors.tertiary : colors.error,
            ),
            const SizedBox(height: 16),
            Text(
              approved ? 'Dossier approuvé' : 'Dossier refusé',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              approved
                  ? (vars.autoApproved == true
                      ? "Approuvé automatiquement par le moteur (score de risque "
                          "faible) — aucune revue manuelle n'a été nécessaire."
                      : "Approuvé par l'agent de conformité après revue manuelle.")
                  : (vars.rejectionReason ?? 'Ce dossier a été refusé.'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: FilledButton(
                onPressed: () =>
                    context.read<OnboardingProcessBloc>().add(const RestartOnboardingProcess()),
                child: const Text('Redémarrer le process'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
