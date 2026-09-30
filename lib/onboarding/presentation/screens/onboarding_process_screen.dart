import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../business_logic/onboarding_process_bloc.dart';
import '../../data/repositories/onboarding_process_repository.dart';
import '../widgets/onboarding_task_switcher.dart';
import '../widgets/process_stepper_header.dart';
import '../widgets/process_variables_inspector.dart';

/// Entry point of the demo — see the repo's README for the full
/// explanation of what this demonstrates and how.
class OnboardingProcessScreen extends StatelessWidget {
  const OnboardingProcessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingProcessBloc(
        repository: OnboardingProcessRepository(),
      )..add(const StartOnboardingProcess()),
      child: const _OnboardingProcessView(),
    );
  }
}

class _OnboardingProcessView extends StatelessWidget {
  const _OnboardingProcessView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démo — Process BPM (onboarding marchand)'),
        actions: [
          IconButton(
            tooltip: 'Redémarrer le process',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () =>
                context.read<OnboardingProcessBloc>().add(const RestartOnboardingProcess()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<OnboardingProcessBloc, OnboardingProcessState>(
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        "Cet écran illustre comment un process BPM pilote l'affichage : "
                        "chaque tâche active du moteur détermine l'écran affiché, et les "
                        "variables du process circulent d'une tâche à l'autre. Le moteur "
                        "BPM est ici entièrement simulé (mock), sans backend.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      ProcessStepperHeader(state: state),
                      const SizedBox(height: 20),
                      OnboardingTaskSwitcher(state: state),
                      const SizedBox(height: 20),
                      ProcessVariablesInspector(process: state.process),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
