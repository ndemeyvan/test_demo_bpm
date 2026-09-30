part of 'onboarding_process_bloc.dart';

sealed class OnboardingProcessState extends ProcessState<OnboardingVariables> {
  const OnboardingProcessState({super.process, super.message});
}

final class OnboardingProcessInitial extends OnboardingProcessState {
  const OnboardingProcessInitial();
}

final class OnboardingProcessLoading extends OnboardingProcessState {
  const OnboardingProcessLoading({super.process});
}

final class OnboardingProcessLoaded extends OnboardingProcessState {
  const OnboardingProcessLoaded({required Process<OnboardingVariables> process})
      : super(process: process);
}

final class OnboardingProcessFailure extends OnboardingProcessState {
  const OnboardingProcessFailure({super.process, required String message})
      : super(message: message);
}
