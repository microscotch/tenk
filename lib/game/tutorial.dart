import 'dice_roll.dart';
import 'turn_state.dart';

/// Ce que le tutoriel attend du joueur à une étape : une seule action est
/// possible à chaque fois, c'est ce qui le guide.
enum TutorialAction { next, roll, keep, stop, finish }

/// Une étape du tutoriel : l'action attendue, et pour un lancer les faces
/// qu'il montre (jamais le hasard : c'est un scénario).
class TutorialStep {
  final TutorialAction action;
  final List<int>? faces;

  const TutorialStep(this.action, [this.faces]);
}

/// Le scénario : un premier tour qui rapporte 700 points (un as et un 5, un
/// brelan qui donne des dés chauds, puis deux as et un 5 qu'il faut garder
/// parce que s'arrêter sur 650 est interdit), puis un second tour qui craque.
/// Chaque étape correspond à un texte `tutorialStep<i>` de l'application.
const tutorialSteps = <TutorialStep>[
  TutorialStep(TutorialAction.next),
  TutorialStep(TutorialAction.roll, [1, 5, 2, 3, 6]),
  TutorialStep(TutorialAction.keep),
  TutorialStep(TutorialAction.roll, [3, 3, 3]),
  TutorialStep(TutorialAction.keep),
  TutorialStep(TutorialAction.roll, [1, 1, 5, 4, 2]),
  TutorialStep(TutorialAction.keep),
  TutorialStep(TutorialAction.stop),
  TutorialStep(TutorialAction.roll, [2, 3, 4, 6, 2]),
  TutorialStep(TutorialAction.finish),
];

/// L'état d'un tutoriel en cours : sa position dans [tutorialSteps] et le tour
/// qu'il fait jouer. Immuable, comme le reste du moteur ; il ne touche à aucune
/// partie (rien n'est enregistré, aucun journal) : il ne fait que rejouer les
/// fonctions pures du moteur sur des dés choisis.
class TutorialSession {
  final int step;

  /// Le tour en cours (les dés du lancer en attente, les dés gardés, le score).
  final TurnState turn;

  /// Les points déjà encaissés : 0 jusqu'à l'arrêt de la 8e étape.
  final int total;

  const TutorialSession({this.step = 0, required this.turn, this.total = 0});

  factory TutorialSession.start() => TutorialSession(turn: TurnState.initial(5));

  TutorialStep get current => tutorialSteps[step];

  bool get isLast => step == tutorialSteps.length - 1;

  /// Joue l'action attendue, ou rend l'état tel quel pour toute autre : le
  /// tutoriel ne laisse faire que ce qu'il explique.
  TutorialSession perform(TutorialAction action) {
    if (action != current.action) return this;
    switch (action) {
      case TutorialAction.next:
        return _at(step + 1, turn);
      case TutorialAction.finish:
        return this;
      case TutorialAction.roll:
        final random = ScriptedRandom(current.faces!);
        final rolled = rollTurn(turn, random: random);
        random.assertConsumed();
        return _at(step + 1, rolled);
      case TutorialAction.keep:
        return _at(step + 1, applyKeepDecision(turn));
      case TutorialAction.stop:
        final attempt = tryBank(turn, minimumRequired: 500, currentTotal: total, isFinalRound: false);
        if (!attempt.success) return this;
        return TutorialSession(step: step + 1, turn: TurnState.initial(5), total: total + attempt.bankedPoints!);
    }
  }

  TutorialSession _at(int newStep, TurnState newTurn) => TutorialSession(step: newStep, turn: newTurn, total: total);
}
