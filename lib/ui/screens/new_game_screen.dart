import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/ai/ai_profiles.dart';
import '../../game/game_setup.dart';
import '../../game/player_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_save_store.dart';
import '../../state/player_store.dart';
import '../ai_character_names.dart';
import '../widgets/player_avatar.dart';
import 'dice_off_screen.dart';
import 'player_picker_screen.dart';

/// Un siège de la partie en préparation : soit un joueur de la base, soit un
/// bot. Un seul type par siège, là où l'écran gérait auparavant quatre listes
/// parallèles (noms, focus, bot, auto) qu'il fallait garder synchronisées.
sealed class _Seat {
  final bool isAuto;
  const _Seat({required this.isAuto});

  String get name;
  _Seat withAuto(bool auto);
}

class _HumanSeat extends _Seat {
  final PlayerProfile profile;
  const _HumanSeat(this.profile, {required super.isAuto});

  @override
  String get name => profile.name;

  @override
  _Seat withAuto(bool auto) => _HumanSeat(profile, isAuto: auto);
}

class _BotSeat extends _Seat {
  @override
  final String name;
  const _BotSeat(this.name, {required super.isAuto});

  @override
  _Seat withAuto(bool auto) => _BotSeat(name, isAuto: auto);
}

class NewGameScreen extends ConsumerStatefulWidget {
  const NewGameScreen({super.key});

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  static const _maxPlayers = 6;
  static const _minPlayers = 2;

  final List<_Seat> _seats = [];
  bool _prefilled = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    _prefillFromLastGame();
  }

  /// Repropose la composition de la dernière partie lancée. Rien n'est stocké
  /// pour ça : la partie la plus récente, en pause ou terminée, porte déjà sa
  /// configuration. Un joueur supprimé de la base depuis est simplement omis.
  Future<void> _prefillFromLastGame() async {
    final games = [
      ...await ref.read(gameSaveStoreProvider).list(),
      ...await ref.read(archivedGameSaveStoreProvider).list(),
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (games.isEmpty || !mounted) return;

    final setup = games.first.setup;
    final byId = {for (final p in await ref.read(playerStoreProvider).list()) p.id: p};
    final seats = <_Seat>[];
    for (var i = 0; i < setup.playerNames.length; i++) {
      if (setup.isAi(i)) {
        seats.add(_BotSeat(setup.playerNames[i], isAuto: setup.isAuto(i)));
        continue;
      }
      final profile = byId[setup.playerIdAt(i)];
      if (profile != null) seats.add(_HumanSeat(profile, isAuto: setup.isAuto(i)));
    }

    if (!mounted || seats.length < _minPlayers) return;
    setState(() => _seats..clear()..addAll(seats));
  }

  Future<void> _addHumans() async {
    final picked = await Navigator.of(context).push<List<PlayerProfile>>(
      MaterialPageRoute(
        builder: (_) => PlayerPickerScreen(
          alreadySeated: {
            for (final seat in _seats)
              if (seat is _HumanSeat) seat.profile.id,
          },
        ),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      for (final profile in picked) {
        if (_seats.length >= _maxPlayers) break;
        // Un humain clique lui-même : pas d'auto-validation par défaut.
        _seats.add(_HumanSeat(profile, isAuto: false));
      }
      _error = null;
    });
  }

  void _addBot() {
    if (_seats.length >= _maxPlayers) return;
    final taken = _seats.map((s) => s.name).toSet();
    final free = kAiCharacterNames.where((n) => !taken.contains(n)).toList();
    final name = free.isEmpty ? kAiCharacterNames.first : free[Random().nextInt(free.length)];
    // Un bot s'auto-valide : rien ne justifie de cliquer à sa place.
    setState(() {
      _seats.add(_BotSeat(name, isAuto: true));
      _error = null;
    });
  }

  void _start() {
    final l10n = AppLocalizations.of(context);
    if (_seats.length < _minPlayers) {
      setState(() => _error = l10n.notEnoughPlayersMessage);
      return;
    }

    final setup = GameSetup(
      playerNames: [for (final seat in _seats) seat.name],
      // Tous les bots au niveau prudent : le réglage de difficulté a disparu.
      // L'énumération reste, et sa lecture aussi, pour que les parties déjà
      // archivées avec un autre niveau continuent de se rejouer.
      aiPlayers: {
        for (var i = 0; i < _seats.length; i++)
          if (_seats[i] is _BotSeat) i: AiDifficulty.prudent,
      },
      autoPlayers: {
        for (var i = 0; i < _seats.length; i++)
          if (_seats[i].isAuto) i,
      },
      playerIds: {
        for (var i = 0; i < _seats.length; i++)
          if (_seats[i] case final _HumanSeat seat) i: seat.profile.id,
      },
    );

    ref.read(diceOffProvider.notifier).start(setup);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiceOffScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newGameSectionLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: l10n.addHumanTooltip,
            onPressed: _seats.length >= _maxPlayers ? null : _addHumans,
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy),
            tooltip: l10n.addBotTooltip,
            onPressed: _seats.length >= _maxPlayers ? null : _addBot,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.playersCountTitle(_seats.length),
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (var i = 0; i < _seats.length; i++) _seatRow(l10n, i),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 32),
              FilledButton(onPressed: _start, child: Text(l10n.startGameButton)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seatRow(AppLocalizations l10n, int index) {
    final seat = _seats[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          PlayerAvatarWidget(name: seat.name, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seat is _HumanSeat ? seat.profile.displayName : seat.name),
                if (seat is _BotSeat)
                  Text(l10n.botLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          FilterChip(
            label: Text(l10n.autoChipLabel),
            avatar: const Icon(Icons.bolt, size: 18),
            selected: seat.isAuto,
            onSelected: (v) => setState(() => _seats[index] = seat.withAuto(v)),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.removeSeatTooltip,
            onPressed: () => setState(() => _seats.removeAt(index)),
          ),
        ],
      ),
    );
  }
}
