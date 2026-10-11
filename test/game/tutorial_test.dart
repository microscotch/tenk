import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/ai/ai_turn.dart';
import 'package:le10000/game/dice_roll.dart';
import 'package:le10000/game/game_engine.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/game/tutorial.dart';

/// Joue une leçon sans écran, comme le ferait un joueur qui suit chaque bulle
/// (et comme l'écran de jeu fait jouer le bot et la prise d'office du 10 000) :
/// rend la suite des étapes montrées et l'état final.
({List<String> beats, GameEngine engine}) play(TutorialLesson lesson) {
  final random = ScriptedRandom(lesson.faces);
  var engine = lesson.setup('Moi', 'Bot');
  final acked = <String>{};
  final shown = <String>[];
  var selectedKeep = 0;
  final prudent = aiStrategyFor(AiDifficulty.prudent);

  // Le sélecteur, comme à l'écran : réglé d'office à chaque nouveau lancer
  // (la leçon, sinon tous les 5), puis changé par le joueur.
  Object? selectionRoll;

  int keepFor(TurnState turn) {
    final roll = turn.pendingRoll!;
    final fives = roll.declinableFives?.diceCount ?? 0;
    return fives - selectedKeep.clamp(minKeepableFives(roll), fives);
  }

  /// Ce que fait `GameNotifier` après un arrêt ou un craque : démarrer seul le
  /// tour suivant quand il n'y a pas de main à choisir.
  GameEngine startIfNoChoice(GameEngine e) =>
      e.activeTurn == null && !e.gameOver && (e.nextTurnDice >= 5 || e.inheritedHandCannotBank)
          ? e.startTurn(useFullHand: e.inheritedHandCannotBank)
          : e;

  for (var step = 0; step < 60; step++) {
    final roll = engine.activeTurn?.pendingRoll;
    if (roll != null && !identical(roll, selectionRoll)) {
      selectionRoll = roll;
      selectedKeep = lesson.defaultKeep(roll.faces) ?? (roll.declinableFives?.diceCount ?? 0);
    }
    final context = TutorialContext(engine: engine, selectedKeep: selectedKeep, acked: acked);
    final beat = lesson.beatFor(context);
    if (beat != null && (shown.isEmpty || shown.last != beat.id)) shown.add(beat.id);
    if (beat != null && beat.isOutro) break;
    final turn = engine.activeTurn;
    if (beat != null && beat.needsAck) {
      acked.add(beat.id);
      continue;
    }
    // Le bot joue seul (voir GameScreen._scheduleAiIfNeeded).
    if (engine.currentPlayerIndex == 1) {
      expect(lesson.botMayPlay(context), isTrue, reason: '${lesson.id}: le bot doit pouvoir jouer');
      final move = nextAiMove(engine, prudent);
      engine = startIfNoChoice(applyGameAction(engine, move, random));
      continue;
    }
    switch (beat?.target) {
      case TutorialTarget.roll:
        if (turn!.pendingRoll != null) engine = engine.applyKeep(declineFivesCount: keepFor(turn));
        engine = engine.roll(random: random);
      case TutorialTarget.exchange:
        selectedKeep = 1;
      case TutorialTarget.stop:
        if (turn!.pendingRoll != null) engine = engine.applyKeep(declineFivesCount: keepFor(turn));
        final (banked, attempt) = engine.bank();
        expect(attempt.success, isTrue, reason: '${lesson.id}: l\'arrêt montré doit être permis');
        engine = startIfNoChoice(banked);
      case TutorialTarget.bustOk:
        engine = startIfNoChoice(engine.endBustedTurn());
      case TutorialTarget.inheritTake:
        // Comme la fenêtre : reprendre la main, c'est aussitôt lancer.
        engine = engine.startTurn(useFullHand: false).roll(random: random);
      case TutorialTarget.opponentRow:
      case TutorialTarget.finalBanner:
        fail('${lesson.id}: une cible à regarder attend « Suivant »');
      case null:
        // Le 10 000 pile se prend d'office (voir _scheduleAutoAdvanceIfNeeded).
        final decline = winningDeclineFivesCount(turn!, turn.pendingRoll!, currentTotal: engine.currentPlayer.totalScore);
        expect(decline, isNotNull, reason: '${lesson.id}: étape sans commande, hors 10 000 pile');
        engine = engine.applyKeep(declineFivesCount: decline!);
        final (banked, _) = engine.bank();
        engine = banked;
    }
  }
  random.assertConsumed();
  return (beats: shown, engine: engine);
}

void main() {
  test('sept leçons, de la plus simple à la plus subtile', () {
    expect(tutorialLessons.map((l) => l.id), TutorialLessonId.values);
    for (final lesson in tutorialLessons) {
      expect(lesson.beats.first.id, TutorialBeat.introId);
      expect(lesson.beats.last.id, TutorialBeat.outroId);
    }
  });

  test('les bases : un as, puis un brelan de 6 — 700 pour entrer', () {
    final run = play(tutorialLesson(TutorialLessonId.basics));
    expect(run.beats, ['intro', 'roll', 'ace', 'brelan', 'outro']);
    expect(run.engine.players[0].totalScore, 700);
  });

  test('la main pleine et les 5 facultatifs : 500, en n\'en gardant qu\'un', () {
    final run = play(tutorialLesson(TutorialLessonId.hotDice));
    expect(run.beats, ['intro', 'roll', 'kept', 'fullHand', 'fives', 'stop', 'outro']);
    expect(run.engine.players[0].totalScore, 500);
  });

  test('le craque : un trait, le bot craque aussi, puis la ligne barrée', () {
    final run = play(tutorialLesson(TutorialLessonId.bust));
    expect(run.beats, ['intro', 'roll', 'tiret', 'botTurn', 'rollAgain', 'barred', 'outro']);
    final me = run.engine.players[0];
    expect(me.totalScore, 500);
    expect(me.grid.firstWhere((e) => e.value == 1500).isBarred, isTrue);
    expect(run.engine.players[1].totalScore, 1000, reason: 'le bot a craqué sans trait… à 1000 il en a un');
  });

  test('l\'extension : le 2 seul vaut 100 après le brelan de 2', () {
    final run = play(tutorialLesson(TutorialLessonId.extension));
    expect(run.beats, ['intro', 'roll', 'brelan', 'extended', 'outro']);
    expect(run.engine.players[0].totalScore, 2300);
  });

  test('la main héritée : le bot s\'arrête à 1000 avec 2 dés, on les reprend', () {
    final run = play(tutorialLesson(TutorialLessonId.inheritedHand));
    expect(run.beats, ['intro', 'botTurn', 'take', 'stop', 'outro']);
    expect(run.engine.players[1].totalScore, 3500);
    expect(run.engine.players[0].totalScore, 4100);
  });

  test('la collision : atteindre 2000 barre le bot, qui retombe à 1500', () {
    final run = play(tutorialLesson(TutorialLessonId.collision));
    expect(run.beats, ['intro', 'roll', 'collide', 'outro']);
    expect(run.engine.players[0].totalScore, 2000);
    expect(run.engine.players[1].totalScore, 1500);
  });

  test('le dernier tour : pas d\'arrêt, 10 000 pile pris d\'office, le bot barré', () {
    final run = play(tutorialLesson(TutorialLessonId.finalRound));
    expect(run.beats, ['intro', 'roll', 'noStop', 'exact', 'outro']);
    expect(run.engine.players[0].totalScore, 10000);
    expect(run.engine.players[1].totalScore, 9000);
    expect(run.engine.gameOver, isFalse, reason: 'au bot de jouer son dernier tour');
  });

  test('dans le dernier tour, s\'arrêter sous 10 000 est refusé', () {
    final lesson = tutorialLesson(TutorialLessonId.finalRound);
    var engine = lesson.setup('Moi', 'Bot').roll(random: ScriptedRandom(const [1, 4, 6, 2, 3]));
    engine = engine.applyKeep();
    expect(engine.bank().$2.success, isFalse);
  });
}
