import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/ai/ai_profiles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/settings_providers.dart';
import '../widgets/app_title.dart';

/// Nom natif de chaque langue supportée, tel qu'un locuteur de cette langue
/// le reconnaît — affiché tel quel dans le sélecteur, indépendamment de la
/// langue actuelle de l'app (voir [AppLocalizations.supportedLocales]).
const Map<String, String> _languageNativeNames = {
  'fr': 'Français',
  'en': 'English',
  'es': 'Español',
  'de': 'Deutsch',
  'it': 'Italiano',
  'pt': 'Português',
  'bg': 'Български',
  'ro': 'Română',
  'nb': 'Norsk bokmål',
  'sv': 'Svenska',
  'fi': 'Suomi',
};

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
    final l10n = AppLocalizations.of(context);
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
              Text(l10n.settingsMainPlayerTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.settingsYourNameLabel,
                  border: const OutlineInputBorder(),
                ),
                onChanged: notifier.setPlayerName,
              ),
              const SizedBox(height: 28),
              Text(l10n.settingsLanguageTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: settings.languageOverride,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.settingsLanguageSystemOption)),
                  for (final code in AppLocalizations.supportedLocales.map((l) => l.languageCode))
                    DropdownMenuItem(value: code, child: Text(_languageNativeNames[code] ?? code)),
                ],
                onChanged: notifier.setLanguageOverride,
              ),
              const SizedBox(height: 28),
              Text(l10n.settingsDelaysTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                l10n.settingsDelaysDescription,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              const SizedBox(height: 12),
              _DelayField(
                label: l10n.settingsAiDelayLabel,
                controller: _aiDelayController,
                onChanged: (ms) => notifier.setAiMessageDelayMs(ms),
              ),
              const SizedBox(height: 12),
              _DelayField(
                label: l10n.settingsAutoActionDelayLabel,
                controller: _autoActionDelayController,
                onChanged: (ms) => notifier.setAutoActionDelayMs(ms),
              ),
              const SizedBox(height: 28),
              Text(l10n.botDifficultyTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<AiDifficulty>(
                segments: [
                  ButtonSegment(value: AiDifficulty.prudent, label: Text(l10n.aiDifficultyCautious)),
                  ButtonSegment(value: AiDifficulty.equilibre, label: Text(l10n.aiDifficultyBalanced)),
                  ButtonSegment(value: AiDifficulty.agressif, label: Text(l10n.aiDifficultyAggressive)),
                ],
                selected: {settings.aiDifficulty},
                onSelectionChanged: (s) => notifier.setAiDifficulty(s.first),
              ),
              const SizedBox(height: 28),
              Text(l10n.settingsDiceTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<DiceColorMode>(
                segments: [
                  ButtonSegment(value: DiceColorMode.uniform, label: Text(l10n.settingsDiceUniform)),
                  ButtonSegment(value: DiceColorMode.varied, label: Text(l10n.settingsDiceVaried)),
                ],
                selected: {settings.diceColorMode},
                onSelectionChanged: (s) => notifier.setDiceColorMode(s.first),
              ),
              const SizedBox(height: 28),
              Text(l10n.settingsSoundsTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsMusicLabel),
                value: settings.musicEnabled,
                onChanged: notifier.setMusicEnabled,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsSoundEffectsLabel),
                value: settings.soundEffectsEnabled,
                onChanged: notifier.setSoundEffectsEnabled,
              ),
              const SizedBox(height: 28),
              Text(l10n.settingsPausedGamesTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.settingsConfirmBeforeDeleteGameLabel),
                value: settings.confirmBeforeDeleteGame,
                onChanged: notifier.setConfirmBeforeDeleteGame,
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
