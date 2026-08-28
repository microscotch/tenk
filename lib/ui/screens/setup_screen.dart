import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/ai/ai_profiles.dart';
import '../../state/game_providers.dart';
import 'game_screen.dart';

enum _Mode { passAndPlay, soloVsAi }

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  _Mode _mode = _Mode.passAndPlay;
  final List<TextEditingController> _passAndPlayNames = [
    TextEditingController(text: 'Joueur 1'),
    TextEditingController(text: 'Joueur 2'),
  ];
  final _soloHumanName = TextEditingController(text: 'Joueur');
  AiDifficulty _aiDifficulty = AiDifficulty.equilibre;

  @override
  void dispose() {
    for (final c in _passAndPlayNames) {
      c.dispose();
    }
    _soloHumanName.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (_passAndPlayNames.length >= 6) return;
    setState(() => _passAndPlayNames.add(
          TextEditingController(text: 'Joueur ${_passAndPlayNames.length + 1}'),
        ));
  }

  void _removePlayer() {
    if (_passAndPlayNames.length <= 2) return;
    setState(() => _passAndPlayNames.removeLast().dispose());
  }

  void _start() {
    final GameSetup setup;
    if (_mode == _Mode.passAndPlay) {
      setup = GameSetup(
        playerNames: [for (final c in _passAndPlayNames) c.text.trim().isEmpty ? 'Joueur' : c.text.trim()],
      );
    } else {
      setup = GameSetup(
        playerNames: [
          _soloHumanName.text.trim().isEmpty ? 'Joueur' : _soloHumanName.text.trim(),
          'IA (${_aiLabel(_aiDifficulty)})',
        ],
        aiPlayers: {1: _aiDifficulty},
      );
    }
    ref.read(gameProvider.notifier).startGame(setup);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  String _aiLabel(AiDifficulty d) => switch (d) {
        AiDifficulty.prudent => 'prudent',
        AiDifficulty.equilibre => 'équilibré',
        AiDifficulty.agressif => 'agressif',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Le 10000')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_Mode>(
                segments: const [
                  ButtonSegment(value: _Mode.passAndPlay, label: Text('Pass-and-play')),
                  ButtonSegment(value: _Mode.soloVsAi, label: Text('Solo vs IA')),
                ],
                selected: {_mode},
                onSelectionChanged: (s) => setState(() => _mode = s.first),
              ),
              const SizedBox(height: 24),
              if (_mode == _Mode.passAndPlay) ..._buildPassAndPlayForm() else ..._buildSoloForm(),
              const SizedBox(height: 32),
              FilledButton(onPressed: _start, child: const Text('Commencer la partie')),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPassAndPlayForm() {
    return [
      Text('Joueurs (${_passAndPlayNames.length})', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (var i = 0; i < _passAndPlayNames.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TextField(
            controller: _passAndPlayNames[i],
            decoration: InputDecoration(labelText: 'Nom du joueur ${i + 1}', border: const OutlineInputBorder()),
          ),
        ),
      Row(
        children: [
          OutlinedButton.icon(
            onPressed: _passAndPlayNames.length < 6 ? _addPlayer : null,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _passAndPlayNames.length > 2 ? _removePlayer : null,
            icon: const Icon(Icons.remove),
            label: const Text('Retirer'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildSoloForm() {
    return [
      TextField(
        controller: _soloHumanName,
        decoration: const InputDecoration(labelText: 'Votre nom', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      Text('Difficulté de l\'IA', style: Theme.of(context).textTheme.titleMedium),
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
    ];
  }
}
