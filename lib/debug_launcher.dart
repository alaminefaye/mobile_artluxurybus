import 'package:flutter/material.dart';
import 'debug/debug_screen.dart';

class DebugLauncher extends StatelessWidget {
  const DebugLauncher({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outils de débogage'),
      ),
      body: const DebugScreen(),
    );
  }
}
