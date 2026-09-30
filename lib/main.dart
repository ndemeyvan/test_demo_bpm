import 'package:flutter/material.dart';

import 'onboarding/presentation/screens/onboarding_process_screen.dart';

void main() {
  runApp(const DemoBpmApp());
}

class DemoBpmApp extends StatelessWidget {
  const DemoBpmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Démo BPM Process',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B5AED)),
        useMaterial3: true,
      ),
      home: const OnboardingProcessScreen(),
    );
  }
}
