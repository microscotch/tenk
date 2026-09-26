import 'dart:math';

import '../../lib/game/dice_off.dart';
import '../../lib/game/dice_roll.dart';
import '../../lib/game/game_engine.dart';
import '../../lib/game/game_recording.dart';
import '../../lib/game/online/protocol.dart';
import '../../lib/game/turn_state.dart';

/// Un coup refusé : ce que le joueur a demandé n'est pas jouable maintenant.
class IntentRejected implements Exception {
  final ErrorCode code;
  final String reason;

  const IntentRejected(this.code, this.reason);

  @override
  String toString() => 'IntentRejected(${code.name}: $reason)';
}

/// L'arbitre d'UNE partie en ligne : détient le générateur aléatoire (que les
/// clients ne connaissent jamais), joue le départage, valide chaque coup et
/// produit le journal — dont chaque lancer porte ses faces, pour que les
/// clients le rejouent avec `replayGame` sans seed.
///
/// Pur Dart et sans I/O : la salle ([Room]) s'occupe des connexions.
class GameAuthority {
  /// Les pseudos dans l'ordre des sièges du salon (avant départage).
  final List<String> names;

  final RecordingRandom _random;
  final DateTime Function() _now;

  DiceOffState _diceOff;
  GameEngine? _engine;
  List<int>? _playOrder;
  final List<GameAction> _actions = [];

  GameAuthority({required this.names, Random? random, DateTime Function()? now})
      : assert(names.length >= minOnlinePlayers && names.length <= maxOnlinePlayers),
        _random = RecordingRandom(random ?? Random.secure()),
        _now = now ?? DateTime.now,
        _diceOff = DiceOffState.start(names.length);

  List<GameAction> get actions => List.unmodifiable(_actions);
  GameEngine? get engine => _engine;
  bool get isStarted => _actions.isNotEmpty;
  bool get isOver => _engine?.gameOver ?? false;

  /// Le siège (celui du salon) qui a la main, ou null hors partie.
  int? get currentSeat {
    final engine = _engine;
    if (engine == null || engine.gameOver) return null;
    return _playOrder![engine.currentPlayerIndex];
  }

  /// Lance la partie : départage (autant de rounds que nécessaire, tout est
  /// tiré d'un coup), puis démarrage du premier tour. Rend les actions produites.
  List<GameAction> start() {
    if (isStarted) throw StateError('la partie a déjà commencé');
    final produced = <GameAction>[];
    while (!_diceOff.isResolved) {
      _random.clear();
      _diceOff = _diceOff.rollAll(random: _random);
      produced.add(GameAction.diceOffRollAll(faces: _random.faces, at: _now()));
      _diceOff = _diceOff.resolveRound();
      produced.add(GameAction.diceOffResolveRound(at: _now()));
    }
    _playOrder = _diceOff.playOrder;
    _engine = GameEngine.newGame([for (final seat in _playOrder!) names[seat]]);
    produced.addAll(_startTurnIfNoChoice(startFresh: true));
    _actions.addAll(produced);
    return produced;
  }

  /// Joue le coup demandé par le joueur du siège [seat]. Rend les actions à
  /// diffuser (le coup, plus les démarrages de tour qui s'enchaînent seuls),
  /// ou lève [IntentRejected] sans rien changer.
  List<GameAction> play(int seat, GameActionType intent, Map<String, dynamic> params) {
    final engine = _engine;
    if (engine == null) throw const IntentRejected(ErrorCode.illegalMove, 'la partie n\'a pas commencé');
    if (engine.gameOver) throw const IntentRejected(ErrorCode.illegalMove, 'la partie est terminée');
    if (seat != currentSeat) throw const IntentRejected(ErrorCode.notYourTurn, 'ce n\'est pas votre tour');

    final GameAction action;
    final GameEngine next;
    try {
      (action, next) = _apply(engine, intent, params);
    } on IntentRejected {
      rethrow;
    } on StateError catch (e) {
      throw IntentRejected(ErrorCode.illegalMove, e.message);
    } on ArgumentError catch (e) {
      throw IntentRejected(ErrorCode.illegalMove, '${e.message}');
    }

    _engine = next;
    final produced = [action, ..._startTurnIfNoChoice()];
    _actions.addAll(produced);
    return produced;
  }

  (GameAction, GameEngine) _apply(GameEngine engine, GameActionType intent, Map<String, dynamic> params) {
    final turn = engine.activeTurn;
    switch (intent) {
      case GameActionType.startTurn:
        final useFullHand = params['useFullHand'] as bool? ?? false;
        // Un vrai choix de main n'existe que s'il y a des dés hérités viables :
        // sinon le tour est déjà parti tout seul (voir _startTurnIfNoChoice).
        if (turn != null || engine.nextTurnDice >= 5 || engine.inheritedHandCannotBank) {
          throw const IntentRejected(ErrorCode.illegalMove, 'aucun choix de main à faire');
        }
        return (GameAction.startTurn(useFullHand: useFullHand, at: _now()), engine.startTurn(useFullHand: useFullHand));

      case GameActionType.roll:
        if (turn == null || turn.pendingRoll != null || turn.busted) {
          throw const IntentRejected(ErrorCode.illegalMove, 'aucun lancer possible maintenant');
        }
        _random.clear();
        final next = engine.roll(random: _random);
        return (GameAction.roll(faces: _random.faces, at: _now()), next);

      case GameActionType.applyKeep:
        final analysis = turn?.pendingRoll;
        if (turn == null || analysis == null || turn.busted) {
          throw const IntentRejected(ErrorCode.illegalMove, 'aucune décision de garde en attente');
        }
        final decline = params['declineFivesCount'] as int? ?? 0;
        final fives = analysis.declinableFives?.diceCount ?? 0;
        final keep = fives - decline;
        final maxKeep = maxKeepableFives(turn, analysis, currentTotal: engine.currentPlayer.totalScore);
        if (decline < 0 || keep < minKeepableFives(analysis) || keep > maxKeep) {
          throw const IntentRejected(ErrorCode.illegalMove, 'nombre de 5 à garder non proposé');
        }
        return (GameAction.applyKeep(declineFivesCount: decline, at: _now()), engine.applyKeep(declineFivesCount: decline));

      case GameActionType.bank:
        if (turn == null || turn.pendingRoll != null || turn.busted) {
          throw const IntentRejected(ErrorCode.illegalMove, 'on ne peut pas s\'arrêter maintenant');
        }
        final (next, attempt) = engine.bank();
        if (!attempt.success) throw const IntentRejected(ErrorCode.illegalMove, 'impossible de banquer');
        return (GameAction.bank(at: _now()), next);

      case GameActionType.endBustedTurn:
        if (turn == null || !turn.busted) {
          throw const IntentRejected(ErrorCode.illegalMove, 'le tour n\'est pas craqué');
        }
        // Un craque remet toujours à 5 dés neufs : le tour suivant part seul.
        return (GameAction.endBustedTurn(at: _now()), engine.endBustedTurn());

      default:
        throw IntentRejected(ErrorCode.badRequest, '${intent.name} n\'est pas un coup jouable');
    }
  }

  /// Démarre seul le tour du joueur courant quand il n'a aucun choix de main à
  /// faire — la même règle que `GameNotifier._startTurnIfNoChoice`, décidée ici
  /// pour que les clients n'aient qu'à appliquer ce qu'ils reçoivent.
  List<GameAction> _startTurnIfNoChoice({bool startFresh = false}) {
    final engine = _engine!;
    if (engine.gameOver || engine.activeTurn != null) return const [];
    final hasChoice = engine.nextTurnDice < 5 && !engine.inheritedHandCannotBank;
    if (hasChoice && !startFresh) return const [];
    final useFullHand = engine.inheritedHandCannotBank;
    _engine = engine.startTurn(useFullHand: useFullHand);
    return [GameAction.startTurn(useFullHand: useFullHand, at: _now())];
  }
}
