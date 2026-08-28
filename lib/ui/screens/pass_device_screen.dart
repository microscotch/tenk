import 'package:flutter/material.dart';

class PassDeviceScreen extends StatelessWidget {
  final String nextPlayerName;

  const PassDeviceScreen({super.key, required this.nextPlayerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.screen_rotation_alt, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Passez l\'appareil à',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  nextPlayerName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Prêt'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
