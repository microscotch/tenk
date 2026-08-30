import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/ai/ai_profiles.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_providers.dart';
import '../../state/settings_providers.dart';
import '../ai_character_names.dart';
import '../widgets/app_title.dart';
import 'dice_off_screen.dart';
import 'settings_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late final List<TextEditingController> _names;
  final List<bool> _isBot = [false, false];

  /// Difficulté partagée par tous les bots de la partie.
  AiDifficulty _aiDifficulty = AiDifficulty.equilibre;

  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    // Le joueur 1 est par défaut le propriétaire de l'appareil, s'il a
    // renseigné son nom dans les réglages.
    final ownerName = ref.read(settingsProvider).playerName.trim();
    _names = [
      TextEditingController(text: ownerName.isEmpty ? 'Joueur 1' : ownerName),
      TextEditingController(text: 'Joueur 2'),
    ];
  }

  bool get _hasAnyBot => _isBot.any((b) => b);

  /// Choisit un nom de personnage du Guide du routard galactique non déjà
  /// utilisé par un autre joueur IA de la partie, si possible.
  String _randomAiName() {
    final used = {for (var i = 0; i < _isBot.length; i++) if (_isBot[i]) _names[i].text};
    final available = kAiCharacterNames.where((n) => !used.contains(n)).toList();
    final pool = available.isNotEmpty ? available : kAiCharacterNames;
    return pool[_random.nextInt(pool.length)];
  }

  /// Bascule le statut IA du joueur [i] : un nom de personnage lui est
  /// attribué dynamiquement dès qu'il devient IA, et le nom par défaut est
  /// restauré s'il redevient humain.
  void _toggleBot(int i, bool isBot) {
    setState(() {
      _isBot[i] = isBot;
      if (isBot) {
        _names[i].text = _randomAiName();
      } else if (kAiCharacterNames.contains(_names[i].text)) {
        _names[i].text = 'Joueur ${i + 1}';
      }
    });
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_names.length >= 6) return;
    setState(() {
      _names.add(TextEditingController(text: 'Joueur ${_names.length + 1}'));
      _isBot.add(false);
    });
  }

  void _removePlayer() {
    if (_names.length <= 2) return;
    setState(() {
      _names.removeLast().dispose();
      _isBot.removeLast();
    });
  }

  void _start() {
    final aiPlayers = <int, AiDifficulty>{
      for (var i = 0; i < _isBot.length; i++)
        if (_isBot[i]) i: _aiDifficulty,
    };
    final setup = GameSetup(
      playerNames: [for (final c in _names) c.text.trim().isEmpty ? 'Joueur' : c.text.trim()],
      aiPlayers: aiPlayers,
    );
    ref.read(diceOffProvider.notifier).start(setup);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiceOffScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Réglages',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Joueurs (${_names.length})', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < _names.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _names[i],
                          decoration: InputDecoration(labelText: 'Nom du joueur ${i + 1}', border: const OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('IA'),
                        avatar: _isBot[i] ? const Icon(Icons.smart_toy, size: 18) : null,
                        selected: _isBot[i],
                        onSelected: (selected) => _toggleBot(i, selected),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _names.length < 6 ? _addPlayer : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _names.length > 2 ? _removePlayer : null,
                    icon: const Icon(Icons.remove),
                    label: const Text('Retirer'),
                  ),
                ],
              ),
              if (_hasAnyBot) ...[
                const SizedBox(height: 24),
                Text('Difficulté des bots', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<AiDifficulty>(
                  segments: const [
                    ButtonSegment(value: AiDifficulty.prudent, label: Text('Prudent')),
                    ButtonSegment(value: AiDifficulty.equilibre, label: Text('Équilibré')),
                    ButtonSegment(value: AiDifficulty.agressif, label: Text('Agressif')),
                  ],
                  selected: {_aiDifficulty},
                  onSelectionChanged: (s) => setState(() => _aiDifficulty = s.first),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(onPressed: _start, child: const Text('Commencer la partie')),
            ],
          ),
        ),
      ),
    );
  }
}
