/// Le tutoriel : sept leçons courtes, de la plus simple à la plus subtile,
/// jouées sur le vrai écran de jeu contre un bot. Chacune part d'une situation
/// préparée ([TutorialLesson.setup]) et de dés choisis ([TutorialLesson.faces],
/// dans l'ordre où le moteur les demande, ceux du bot compris : jamais le
/// hasard). Le bot joue au niveau prudent, qui ne tire rien au hasard : avec les
/// mêmes dés, il prend toujours les mêmes décisions — les tests le vérifient.
///
/// L'étape en cours ([TutorialLesson.beatFor]) se déduit de l'état de la partie
/// et des « Suivant » déjà touchés, jamais d'un compteur qui dériverait de ce
/// qu'on voit.
library;

import 'game_engine.dart';
import 'player.dart';
import 'turn_state.dart';

/// Les leçons, dans l'ordre du parcours.
enum TutorialLessonId { basics, hotDice, bust, extension, inheritedHand, collision, finalRound }

/// Ce qu'une bulle montre : une commande à toucher, ou un élément de l'écran à
/// regarder (alors avec son propre bouton « Suivant »).
enum TutorialTarget {
  /// Le bouton de lancer.
  roll,

  /// Le sélecteur du nombre de 5 à garder.
  exchange,

  /// Le bouton « S'arrêter ».
  stop,

  /// Le ✓ de la fenêtre de craque.
  bustOk,

  /// « Reprendre la main » de la fenêtre de main héritée.
  inheritTake,

  /// La ligne du bot dans la liste des joueurs (son radar).
  opponentRow,

  /// Le bandeau du dernier tour.
  finalBanner;

  /// Vrai pour une commande d'une fenêtre (craque, main héritée), au-dessus de
  /// l'écran de jeu.
  bool get inDialog => this == bustOk || this == inheritTake;
}

/// Ce que voit une étape pour décider si c'est son tour.
class TutorialContext {
  final GameEngine engine;

  /// Le nombre de 5 que le sélecteur indique.
  final int selectedKeep;

  /// Les étapes dont le « Suivant » a déjà été touché.
  final Set<String> acked;

  const TutorialContext({required this.engine, required this.selectedKeep, this.acked = const {}});

  /// Le joueur (toujours l'index 0) et le bot (index 1).
  Player get me => engine.players[0];
  Player get bot => engine.players[1];

  bool get myTurn => engine.currentPlayerIndex == 0;
  TurnState? get turn => engine.activeTurn;

  /// Les faces du lancer en attente, ou null.
  List<int>? get pendingFaces => turn?.pendingRoll?.faces;

  /// Vrai quand le lancer en attente montre exactement [faces].
  bool showing(List<int> faces) {
    final shown = pendingFaces;
    if (shown == null || shown.length != faces.length) return false;
    for (var i = 0; i < faces.length; i++) {
      if (shown[i] != faces[i]) return false;
    }
    return true;
  }

  /// À moi de lancer, rien n'étant en attente.
  bool get myIdleTurn => myTurn && turn != null && !turn!.busted && turn!.pendingRoll == null;
}

/// Une étape d'une leçon : son texte (`id`, voir l'interface), ce qu'elle
/// montre ([target]), si elle attend un « Suivant » ([needsAck]) plutôt qu'une
/// action dans la partie, et quand elle s'applique ([when]).
class TutorialBeat {
  final String id;
  final TutorialTarget? target;
  final bool needsAck;
  final bool Function(TutorialContext context) when;

  const TutorialBeat(this.id, {this.target, this.needsAck = false, required this.when});

  /// Vrai pour l'étape de conclusion d'une leçon (son bouton mène à la suite).
  bool get isOutro => id == outroId;

  static const introId = 'intro';
  static const outroId = 'outro';
}

/// Une leçon : sa situation de départ, ses dés, ses étapes, et quand elle est
/// finie.
class TutorialLesson {
  final TutorialLessonId id;

  /// La partie de départ, entre [me] (index 0) et [bot] (index 1). Le tour
  /// du joueur courant est déjà démarré.
  final GameEngine Function(String me, String bot) setup;

  /// Les dés, dans l'ordre où le moteur les tire (bot compris).
  final List<int> faces;

  /// Les étapes, de la première à la dernière : la première qui s'applique
  /// (et n'a pas déjà eu son « Suivant ») est celle qu'on montre.
  final List<TutorialBeat> beats;

  /// La leçon est finie : on n'y montre plus que sa conclusion.
  final bool Function(TutorialContext context) finished;

  /// Le bot joue-t-il dans cette leçon ? (Sinon la leçon se termine avant son
  /// tour.)
  final bool botPlays;

  /// Le nombre de 5 que le sélecteur indique d'office pour un lancer donné (le
  /// choix par défaut de l'écran vise le meilleur score, et pourrait sortir du
  /// scénario) ; null : celui de l'écran.
  final int? Function(List<int> faces) defaultKeep;

  const TutorialLesson({
    required this.id,
    required this.setup,
    required this.faces,
    required this.beats,
    required this.finished,
    this.botPlays = false,
    this.defaultKeep = _noDefaultKeep,
  });

  static int? _noDefaultKeep(List<int> faces) => null;

  /// L'étape à montrer maintenant : l'introduction d'abord, la conclusion une
  /// fois la leçon finie, sinon la première étape qui s'applique ; null entre
  /// deux étapes (la partie passe d'un état à l'autre, ou le bot joue sans
  /// rien à expliquer).
  TutorialBeat? beatFor(TutorialContext context) {
    final intro = beats.first;
    if (!context.acked.contains(intro.id)) return intro;
    if (finished(context)) return beats.last;
    for (final beat in beats.skip(1).take(beats.length - 2)) {
      if (beat.needsAck && context.acked.contains(beat.id)) continue;
      if (beat.when(context)) return beat;
    }
    return null;
  }

  /// Le bot peut-il jouer maintenant : seulement dans une leçon qui le prévoit,
  /// après l'introduction et avant la fin.
  bool botMayPlay(TutorialContext context) =>
      botPlays && context.acked.contains(beats.first.id) && !finished(context);
}

bool _always(TutorialContext _) => true;

TutorialBeat _intro({TutorialTarget? target}) =>
    TutorialBeat(TutorialBeat.introId, target: target, needsAck: true, when: _always);

const _outro = TutorialBeat(TutorialBeat.outroId, needsAck: true, when: _always);

/// Une partie de départ : le joueur ([me]) et le bot dans l'état voulu, [current]
/// ayant la main, son tour démarré.
GameEngine _game(String me, String bot, {required Player mine, required Player his, int current = 0, int? holder}) {
  return GameEngine(
    players: [mine, his],
    currentPlayerIndex: current,
    nextTurnDice: 5,
    triggeringWinnerIndex: holder,
    remainingFinalTurns: holder == null ? null : 1,
  ).startTurn();
}

/// Les sept leçons, dans l'ordre du parcours.
final List<TutorialLesson> tutorialLessons = [
  // 1. Les bases : lancer, garder ce qui rapporte, entrer dans la partie à 500.
  TutorialLesson(
    id: TutorialLessonId.basics,
    setup: (me, bot) => _game(me, bot, mine: Player(name: me), his: Player(name: bot)),
    faces: const [1, 3, 3, 4, 6, 6, 6, 6, 2],
    beats: [
      _intro(),
      TutorialBeat('roll', target: TutorialTarget.roll, when: (c) => c.myIdleTurn && c.turn!.bankedScore == 0),
      TutorialBeat('ace', target: TutorialTarget.roll, when: (c) => c.showing(const [1, 3, 3, 4, 6])),
      TutorialBeat('brelan', target: TutorialTarget.stop, when: (c) => c.showing(const [6, 6, 6, 2])),
      _outro,
    ],
    finished: (c) => c.me.totalScore > 0,
  ),

  // 2. La main pleine, les 5 facultatifs, jamais d'arrêt sur un total en 50.
  TutorialLesson(
    id: TutorialLessonId.hotDice,
    setup: (me, bot) => _game(me, bot, mine: Player(name: me), his: Player(name: bot)),
    faces: const [1, 5, 2, 3, 6, 3, 3, 3, 5, 5, 2, 3, 6],
    beats: [
      _intro(),
      TutorialBeat('roll', target: TutorialTarget.roll, when: (c) => c.myIdleTurn && c.turn!.bankedScore == 0),
      TutorialBeat('kept', target: TutorialTarget.roll, when: (c) => c.showing(const [1, 5, 2, 3, 6])),
      TutorialBeat('fullHand', target: TutorialTarget.roll, when: (c) => c.showing(const [3, 3, 3])),
      TutorialBeat(
        'fives',
        target: TutorialTarget.exchange,
        when: (c) => c.showing(const [5, 5, 2, 3, 6]) && c.selectedKeep != 1,
      ),
      TutorialBeat('stop', target: TutorialTarget.stop, when: (c) => c.showing(const [5, 5, 2, 3, 6])),
      _outro,
    ],
    finished: (c) => c.me.totalScore > 0,
    // Le premier lancer garde son 5 ; le troisième propose d'abord les deux.
    defaultKeep: (faces) => switch (faces) {
      [1, 5, 2, 3, 6] => 1,
      [5, 5, 2, 3, 6] => 2,
      _ => null,
    },
  ),

  // 3. Le craque : le petit trait, puis la ligne barrée au second.
  TutorialLesson(
    id: TutorialLessonId.bust,
    setup: (me, bot) => _game(
      me,
      bot,
      mine: Player(name: me, totalScore: 1500, previousScore: 500, hasEntered: true),
      his: Player(name: bot, totalScore: 1000, hasEntered: true),
    ),
    faces: const [2, 3, 4, 6, 2, 2, 3, 4, 6, 3, 3, 4, 6, 2, 2],
    botPlays: true,
    beats: [
      _intro(),
      TutorialBeat('roll', target: TutorialTarget.roll, when: (c) => c.myIdleTurn && !c.me.hasTiret),
      TutorialBeat('tiret', target: TutorialTarget.bustOk, when: (c) => c.myTurn && c.turn!.busted && !c.me.hasTiret),
      TutorialBeat('botTurn', when: (c) => !c.myTurn),
      TutorialBeat('rollAgain', target: TutorialTarget.roll, when: (c) => c.myIdleTurn && c.me.hasTiret),
      TutorialBeat('barred', target: TutorialTarget.bustOk, when: (c) => c.myTurn && c.turn!.busted && c.me.hasTiret),
      _outro,
    ],
    finished: (c) => c.me.totalScore == 500,
  ),

  // 4. La règle d'extension : un 2 seul vaut 100 après un brelan de 2.
  TutorialLesson(
    id: TutorialLessonId.extension,
    setup: (me, bot) => _game(
      me,
      bot,
      mine: Player(name: me, totalScore: 2000, hasEntered: true),
      his: Player(name: bot, totalScore: 1500, hasEntered: true),
    ),
    faces: const [2, 2, 2, 4, 6, 2, 6],
    beats: [
      _intro(),
      TutorialBeat('roll', target: TutorialTarget.roll, when: (c) => c.myIdleTurn && c.turn!.bankedScore == 0),
      TutorialBeat('brelan', target: TutorialTarget.roll, when: (c) => c.showing(const [2, 2, 2, 4, 6])),
      TutorialBeat('extended', target: TutorialTarget.stop, when: (c) => c.showing(const [2, 6])),
      _outro,
    ],
    finished: (c) => c.me.totalScore > 2000,
  ),

  // 5. La main héritée : reprendre les dés et les points du bot.
  TutorialLesson(
    id: TutorialLessonId.inheritedHand,
    setup: (me, bot) => _game(
      me,
      bot,
      mine: Player(name: me, totalScore: 3000, hasEntered: true),
      his: Player(name: bot, totalScore: 2500, hasEntered: true),
      current: 1,
    ),
    faces: const [1, 1, 1, 4, 6, 1, 3],
    botPlays: true,
    beats: [
      _intro(),
      TutorialBeat('botTurn', when: (c) => !c.myTurn),
      // Reprendre la main lance aussitôt les dés hérités : il faut lancer au
      // moins une fois avant de s'arrêter.
      TutorialBeat('take', target: TutorialTarget.inheritTake, when: (c) => c.myTurn && c.turn == null),
      TutorialBeat('stop', target: TutorialTarget.stop, when: (c) => c.showing(const [1, 3])),
      _outro,
    ],
    finished: (c) => c.me.totalScore > 3000,
  ),

  // 6. Barrer un adversaire en atteignant son score.
  TutorialLesson(
    id: TutorialLessonId.collision,
    setup: (me, bot) => _game(
      me,
      bot,
      mine: Player(name: me, totalScore: 1800, hasEntered: true),
      his: Player(name: bot, totalScore: 2000, previousScore: 1500, hasEntered: true),
    ),
    faces: const [1, 1, 4, 6, 3],
    beats: [
      _intro(target: TutorialTarget.opponentRow),
      TutorialBeat('roll', target: TutorialTarget.roll, when: (c) => c.myIdleTurn && c.turn!.bankedScore == 0),
      TutorialBeat('collide', target: TutorialTarget.stop, when: (c) => c.showing(const [1, 1, 4, 6, 3])),
      _outro,
    ],
    finished: (c) => c.bot.totalScore == 1500,
  ),

  // 7. Le dernier tour : impossible de s'arrêter, 10 000 pile pris d'office.
  TutorialLesson(
    id: TutorialLessonId.finalRound,
    setup: (me, bot) => _game(
      me,
      bot,
      mine: Player(name: me, totalScore: 9500, hasEntered: true),
      his: Player(name: bot, totalScore: 10000, previousScore: 9000, hasEntered: true),
      holder: 1,
    ),
    faces: const [1, 4, 6, 2, 3, 4, 4, 4, 6],
    beats: [
      _intro(target: TutorialTarget.finalBanner),
      TutorialBeat('roll', target: TutorialTarget.roll, when: (c) => c.myIdleTurn && c.turn!.bankedScore == 0),
      TutorialBeat('noStop', target: TutorialTarget.roll, when: (c) => c.showing(const [1, 4, 6, 2, 3])),
      TutorialBeat('exact', when: (c) => c.showing(const [4, 4, 4, 6])),
      _outro,
    ],
    finished: (c) => c.me.totalScore == winningScore,
  ),
];

/// La leçon [id].
TutorialLesson tutorialLesson(TutorialLessonId id) => tutorialLessons.firstWhere((l) => l.id == id);
