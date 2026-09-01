import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/ai/ai_profiles.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_providers.dart';
import '../../state/game_save_store.dart';
import '../../state/settings_providers.dart';
import '../ai_character_names.dart';
import '../route_observer.dart';
import '../widgets/app_title.dart';
import '../widgets/bordered_section.dart';
import '../widgets/finished_games_list.dart';
import '../widgets/paused_games_list.dart';
import 'dice_off_screen.dart';
import 'settings_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> with RouteAware {
  late final List<TextEditingController> _names;
  late final List<FocusNode> _nameFocusNodes;
  late final List<bool> _isBot;
  late final List<bool> _isAuto;

  /// Index de la zone actuellement ouverte parmi les 3 (accordéon : une
  /// seule à la fois), ou null si toutes sont fermées. "Nouveau run..."
  /// (index 0) est ouverte par défaut.
  int? _expandedSection = 0;

  void _toggleSection(int index) {
    setState(() => _expandedSection = _expandedSection == index ? null : index);
  }

  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    final ownerName = ref.read(settingsProvider).playerName.trim();
    // Par défaut : le propriétaire de l'appareil (humain) et une IA, tous
    // deux en mode auto désactivé (chaque action attend un clic manuel).
    _names = [
      TextEditingController(text: ownerName.isEmpty ? AppLocalizations.of(context).defaultPlayerName(1) : ownerName),
      TextEditingController(text: kAiCharacterNames[_random.nextInt(kAiCharacterNames.length)]),
    ];
    _nameFocusNodes = [for (var i = 0; i < _names.length; i++) _newNameFocusNode()];
    _isBot = [false, true];
    _isAuto = [false, false];

    if (ownerName.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptForOwnerName());
    }
  }

  /// Un `FocusNode` par champ de nom de joueur : le listener déclenche un
  /// rebuild à la perte de focus, pour basculer le champ vers son rendu
  /// tronqué en lecture seule (voir `_PlayerNameField`).
  FocusNode _newNameFocusNode() => FocusNode()..addListener(() => setState(() {}));

  /// Demande son nom au propriétaire de l'appareil s'il n'est pas déjà
  /// renseigné dans les préférences ; sautable (le nom par défaut reste).
  Future<void> _promptForOwnerName() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ownerNameDialogTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.ownerNameFieldLabel),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.laterButton)),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.validateButton),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    ref.read(settingsProvider.notifier).setPlayerName(name);
    setState(() => _names[0].text = name);
  }

  /// Choisit un nom de personnage du Guide du routard galactique non déjà
  /// utilisé par un autre joueur IA de la partie, si possible.
  String _randomAiName() {
    final used = {
      for (var i = 0; i < _isBot.length; i++)
        if (_isBot[i]) _names[i].text,
    };
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
        _names[i].text = AppLocalizations.of(context).defaultPlayerName(i + 1);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) routeObserver.subscribe(this, route);
  }

  /// Cet écran n'est jamais re-poussé (il reste toujours la toute première
  /// route de la pile, voir `game_over_screen.dart`) : `initState` ne
  /// s'exécute donc qu'une fois. `didPopNext` (une route poussée par-dessus
  /// vient d'être dépilée) est le bon moment pour rafraîchir la liste des
  /// parties en pause.
  @override
  void didPopNext() => ref.invalidate(pausedGamesProvider);

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    for (final c in _names) {
      c.dispose();
    }
    for (final f in _nameFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    if (_names.length >= 6) return;
    setState(() {
      _names.add(TextEditingController(text: AppLocalizations.of(context).defaultPlayerName(_names.length + 1)));
      _nameFocusNodes.add(_newNameFocusNode());
      _isBot.add(false);
      _isAuto.add(false);
    });
  }

  void _removePlayer() {
    if (_names.length <= 2) return;
    setState(() {
      _names.removeLast().dispose();
      _nameFocusNodes.removeLast().dispose();
      _isBot.removeLast();
      _isAuto.removeLast();
    });
  }

  void _start() {
    final aiDifficulty = ref.read(settingsProvider).aiDifficulty;
    final aiPlayers = <int, AiDifficulty>{
      for (var i = 0; i < _isBot.length; i++)
        if (_isBot[i]) i: aiDifficulty,
    };
    final autoPlayers = {
      for (var i = 0; i < _isAuto.length; i++)
        if (_isAuto[i]) i,
    };
    final setup = GameSetup(
      playerNames: [
        for (final c in _names)
          c.text.trim().isEmpty ? AppLocalizations.of(context).unnamedPlayerFallback : c.text.trim(),
      ],
      aiPlayers: aiPlayers,
      autoPlayers: autoPlayers,
    );
    ref.read(diceOffProvider.notifier).start(setup);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiceOffScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsTooltip,
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
              BorderedSection(
                label: l10n.newGameSectionLabel,
                isExpanded: _expandedSection == 0,
                onHeaderTap: () => _toggleSection(0),
                child: _buildNewGameSection(context, l10n),
              ),
              const SizedBox(height: 20),
              BorderedSection(
                label: l10n.pausedGamesSectionLabel,
                isExpanded: _expandedSection == 1,
                onHeaderTap: () => _toggleSection(1),
                child: const PausedGamesList(),
              ),
              const SizedBox(height: 20),
              BorderedSection(
                label: l10n.finishedRunsSectionLabel,
                isExpanded: _expandedSection == 2,
                onHeaderTap: () => _toggleSection(2),
                child: const FinishedGamesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewGameSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.playersCountTitle(_names.length), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < _names.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _PlayerNameField(
                    controller: _names[i],
                    focusNode: _nameFocusNodes[i],
                    label: l10n.playerNameFieldLabel(i + 1),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.autoChipLabel),
                  avatar: const Icon(Icons.bolt, size: 18),
                  selected: _isAuto[i],
                  onSelected: (selected) => setState(() => _isAuto[i] = selected),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.aiChipLabel),
                  avatar: const Icon(Icons.smart_toy, size: 18),
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
              label: Text(l10n.addPlayerButton),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _names.length > 2 ? _removePlayer : null,
              icon: const Icon(Icons.remove),
              label: Text(l10n.removePlayerButton),
            ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton(onPressed: _start, child: Text(l10n.startGameButton)),
      ],
    );
  }
}

/// Champ de nom de joueur à 2 rendus : un `TextField` éditable tant qu'il a
/// le focus, remplacé par un `Text` tronqué (`…`) en lecture seule dès que
/// le focus est perdu et que le nom dépasse la largeur disponible — le tap
/// redonne le focus pour reprendre l'édition.
class _PlayerNameField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;

  const _PlayerNameField({required this.controller, required this.focusNode, required this.label});

  @override
  Widget build(BuildContext context) {
    if (focusNode.hasFocus) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      );
    }
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: focusNode.requestFocus,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(
          controller.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
