import 'package:flutter/material.dart';

class ProcessLoadingView extends StatelessWidget {
  const ProcessLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(48),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
