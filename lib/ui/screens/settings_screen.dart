import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings_providers.dart';
import '../widgets/app_title.dart';

/// Écran de configuration : préférences persistées indépendamment de toute
/// partie en cours (nom du joueur principal, temporisations, couleur des
/// dés, sons).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _aiDelayController;
  late final TextEditingController _autoActionDelayController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _nameController = TextEditingController(text: settings.playerName);
    _aiDelayController = TextEditingController(text: settings.aiMessageDelayMs.toString());
    _autoActionDelayController = TextEditingController(text: settings.autoActionDelayMs.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aiDelayController.dispose();
    _autoActionDelayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const AppTitle()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Joueur principal', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Votre nom (propriétaire de l\'appareil)',
                  border: OutlineInputBorder(),
                ),
                onChanged: notifier.setPlayerName,
              ),
              const SizedBox(height: 28),
              Text('Temporisations', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Délai avant qu\'une action automatique ne se déclenche seule. 0 pour désactiver.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _DelayField(
                label: 'Messages IA (ms)',
                controller: _aiDelayController,
                onChanged: (ms) => notifier.setAiMessageDelayMs(ms),
              ),
              const SizedBox(height: 12),
              _DelayField(
                label: 'Actions automatiques du joueur humain (ms)',
                controller: _autoActionDelayController,
                onChanged: (ms) => notifier.setAutoActionDelayMs(ms),
              ),
              const SizedBox(height: 28),
              Text('Dés', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<DiceColorMode>(
                segments: const [
                  ButtonSegment(value: DiceColorMode.uniform, label: Text('Uniforme')),
                  ButtonSegment(value: DiceColorMode.varied, label: Text('Panachée')),
                ],
                selected: {settings.diceColorMode},
                onSelectionChanged: (s) => notifier.setDiceColorMode(s.first),
              ),
              const SizedBox(height: 28),
              Text('Sons', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Musique de fond'),
                value: settings.musicEnabled,
                onChanged: notifier.setMusicEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Effets sonores'),
                value: settings.soundEffectsEnabled,
                onChanged: notifier.setSoundEffectsEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DelayField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  const _DelayField({required this.label, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      onChanged: (text) {
        final ms = int.tryParse(text);
        if (ms != null && ms >= 0) onChanged(ms);
      },
    );
  }
}
