import 'game_engine.dart';

/// Les dés du tutoriel, dans l'ordre où le moteur les demande : jamais le
/// hasard, c'est un scénario. Trois lancers de la même main :
///
/// 1. `1 5 2 3 6` — l'as et le 5 se gardent (150), il reste 3 dés ;
/// 2. `3 3 3` — un brelan (300, soit 450) qui emploie tous les dés : main pleine ;
/// 3. `5 5 2 3 6` — deux 5 facultatifs. Les garder tous les deux ferait 550, un
///    total en 50 sur lequel on n'a pas le droit de s'arrêter ; n'en garder
///    qu'un fait 500, l'entrée dans la partie.
const tutorialFaces = <int>[1, 5, 2, 3, 6, 3, 3, 3, 5, 5, 2, 3, 6];

/// Le nombre de 5 à garder au troisième lancer pour pouvoir s'arrêter.
const tutorialKeepFives = 1;

/// Le nombre de 5 que le sélecteur indique d'office pour ce lancer, ou nul hors
/// scénario : le choix par défaut de l'écran de jeu vise le meilleur score, et
/// pourrait écarter le 5 du premier lancer (le scénario s'arrêterait là) ou ne
/// garder qu'un des deux du troisième (l'étape du sélecteur n'aurait plus rien
/// à montrer).
int? tutorialDefaultKeep(List<int> faces) {
  if (_sameFaces(faces, tutorialFaces.sublist(0, 5))) {
    return 1;
  }
  if (_sameFaces(faces, tutorialFaces.sublist(8))) {
    return tutorialKeepFives + 1;
  }
  return null;
}

bool _sameFaces(List<int> faces, List<int> expected) =>
    faces.length == expected.length &&
    [for (var i = 0; i < faces.length; i++) faces[i] == expected[i]]
        .every((x) => x);

/// La commande de l'écran de jeu qu'une étape fait toucher.
enum TutorialTarget { roll, exchange, stop }

/// Une étape du tutoriel. Chacune a son texte `tutorialStep<index>` dans
/// l'application, dans l'ordre de cette énumération : en ajouter une, c'est
/// ajouter ce texte dans toutes les langues.
enum TutorialStep {
  /// Accueil : seule action, « Suivant ».
  intro(null),

  /// Aucun dé lancé : premier lancer.
  rollFirst(TutorialTarget.roll),

  /// Premier lancer à l'écran : l'as et le 5 se gardent, on relance les 3 autres.
  rollAgain(TutorialTarget.roll),

  /// Le brelan a employé tous les dés : main pleine, on relance les 5.
  hotDice(TutorialTarget.roll),

  /// Deux 5 : le sélecteur d'échange décide combien en garder.
  exchange(TutorialTarget.exchange),

  /// Un seul 5 gardé : 500, on peut s'arrêter.
  stop(TutorialTarget.stop),

  /// Points encaissés : fin, seule action « Commencer à jouer ».
  outro(null),

  /// Entre deux étapes (le tour est en train de passer d'un état à l'autre) :
  /// ni bulle, ni commande.
  waiting(null);

  /// La commande à toucher ; nulle quand la bulle n'attend qu'un bouton à elle.
  final TutorialTarget? target;

  const TutorialStep(this.target);

  /// Vrai quand la bulle porte elle-même le bouton qui fait avancer.
  bool get hasOwnButton => this == intro || this == outro;
}

/// Où en est le tutoriel, d'après le moteur de la partie qu'il fait jouer :
/// c'est l'état de la partie qui commande l'étape, jamais un compteur qui
/// dériverait de ce qu'on voit. [introDone] : « Suivant » a été touché.
/// [selectedKeep] : le nombre de 5 que le sélecteur indique.
TutorialStep tutorialStepFor(
  GameEngine engine, {
  required bool introDone,
  required int selectedKeep,
}) {
  if (!introDone) {
    return TutorialStep.intro;
  }
  if (engine.gameOver || engine.players.first.totalScore > 0) {
    return TutorialStep.outro;
  }
  final turn = engine.activeTurn;
  if (turn == null) {
    return TutorialStep.waiting;
  }
  final roll = turn.pendingRoll;
  if (roll == null) {
    return turn.bankedScore == 0 && turn.keptDiceThisTurn.isEmpty
        ? TutorialStep.rollFirst
        : TutorialStep.waiting;
  }
  final faces = roll.faces;
  if (_sameFaces(faces, tutorialFaces.sublist(0, 5))) {
    return TutorialStep.rollAgain;
  }
  if (_sameFaces(faces, tutorialFaces.sublist(5, 8))) {
    return TutorialStep.hotDice;
  }
  if (_sameFaces(faces, tutorialFaces.sublist(8))) {
    return selectedKeep == tutorialKeepFives
        ? TutorialStep.stop
        : TutorialStep.exchange;
  }
  return TutorialStep.waiting;
}
