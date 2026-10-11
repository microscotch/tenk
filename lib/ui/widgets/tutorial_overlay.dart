import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/game_engine.dart';
import '../../game/tutorial.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';

/// Ce que l'écran de jeu doit au tutoriel en cours : la leçon et sa place dans
/// le parcours, les « Suivant » déjà touchés, une clé par élément qu'une bulle
/// peut montrer (posées sur les vrais éléments de l'écran et de ses fenêtres),
/// et les sorties — la leçon suivante ou la fin du tutoriel.
class TutorialGuide extends ChangeNotifier {
  final TutorialLesson lesson;

  /// La place de la leçon dans le parcours (à partir de 1), et sa longueur.
  final int number;
  final int total;

  /// Vrai quand une autre leçon suit celle-ci dans le parcours.
  final bool hasNext;

  /// La leçon finie : la suivante, ou la fin du tutoriel.
  final VoidCallback onLessonDone;

  /// Quitte le tutoriel (« Passer », retour système).
  final VoidCallback onExit;

  final Set<String> _acked = {};
  final Map<TutorialTarget, GlobalKey> _keys = {
    for (final target in TutorialTarget.values) target: GlobalKey(debugLabel: 'tutorial-${target.name}'),
  };

  TutorialGuide({
    required this.lesson,
    required this.number,
    required this.total,
    required this.hasNext,
    required this.onLessonDone,
    required this.onExit,
  });

  GlobalKey keyFor(TutorialTarget target) => _keys[target]!;

  TutorialContext contextFor(GameEngine engine, {int selectedKeep = 0}) =>
      TutorialContext(engine: engine, selectedKeep: selectedKeep, acked: _acked);

  /// L'étape à montrer pour [engine] (voir [TutorialLesson.beatFor]).
  TutorialBeat? beatFor(GameEngine engine, {int selectedKeep = 0}) =>
      lesson.beatFor(contextFor(engine, selectedKeep: selectedKeep));

  /// Le bot peut-il jouer maintenant (voir [TutorialLesson.botMayPlay]).
  bool botMayPlay(GameEngine engine) => lesson.botMayPlay(contextFor(engine));

  /// Le bouton d'une bulle : « Suivant », ou la sortie de la leçon.
  void press(TutorialBeat beat) {
    if (beat.isOutro) return onLessonDone();
    _acked.add(beat.id);
    notifyListeners();
  }
}

/// Le titre d'une leçon.
String tutorialLessonTitle(AppLocalizations l10n, TutorialLessonId id) => switch (id) {
  TutorialLessonId.basics => l10n.tutorialLessonBasics,
  TutorialLessonId.hotDice => l10n.tutorialLessonHotDice,
  TutorialLessonId.bust => l10n.tutorialLessonBust,
  TutorialLessonId.extension => l10n.tutorialLessonExtension,
  TutorialLessonId.inheritedHand => l10n.tutorialLessonInheritedHand,
  TutorialLessonId.collision => l10n.tutorialLessonCollision,
  TutorialLessonId.finalRound => l10n.tutorialLessonFinalRound,
};

/// Le texte d'une étape d'une leçon.
String tutorialBeatText(AppLocalizations l10n, TutorialLessonId lesson, String beat) {
  if (beat == 'roll') return l10n.tutorialRollPrompt;
  if (beat == 'botTurn') return l10n.tutorialBotTurn;
  return switch ((lesson, beat)) {
    (TutorialLessonId.basics, 'intro') => l10n.tutorialBasicsIntro,
    (TutorialLessonId.basics, 'ace') => l10n.tutorialBasicsAce,
    (TutorialLessonId.basics, 'brelan') => l10n.tutorialBasicsBrelan,
    (TutorialLessonId.basics, 'outro') => l10n.tutorialBasicsOutro,
    (TutorialLessonId.hotDice, 'intro') => l10n.tutorialHotDiceIntro,
    (TutorialLessonId.hotDice, 'kept') => l10n.tutorialHotDiceKept,
    (TutorialLessonId.hotDice, 'fullHand') => l10n.tutorialHotDiceFullHand,
    (TutorialLessonId.hotDice, 'fives') => l10n.tutorialHotDiceFives,
    (TutorialLessonId.hotDice, 'stop') => l10n.tutorialHotDiceStop,
    (TutorialLessonId.hotDice, 'outro') => l10n.tutorialHotDiceOutro,
    (TutorialLessonId.bust, 'intro') => l10n.tutorialBustIntro,
    (TutorialLessonId.bust, 'tiret') => l10n.tutorialBustTiret,
    (TutorialLessonId.bust, 'rollAgain') => l10n.tutorialBustRollAgain,
    (TutorialLessonId.bust, 'barred') => l10n.tutorialBustBarred,
    (TutorialLessonId.bust, 'outro') => l10n.tutorialBustOutro,
    (TutorialLessonId.extension, 'intro') => l10n.tutorialExtensionIntro,
    (TutorialLessonId.extension, 'brelan') => l10n.tutorialExtensionBrelan,
    (TutorialLessonId.extension, 'extended') => l10n.tutorialExtensionExtended,
    (TutorialLessonId.extension, 'outro') => l10n.tutorialExtensionOutro,
    (TutorialLessonId.inheritedHand, 'intro') => l10n.tutorialInheritIntro,
    (TutorialLessonId.inheritedHand, 'take') => l10n.tutorialInheritTake,
    (TutorialLessonId.inheritedHand, 'stop') => l10n.tutorialInheritStop,
    (TutorialLessonId.inheritedHand, 'outro') => l10n.tutorialInheritOutro,
    (TutorialLessonId.collision, 'intro') => l10n.tutorialCollisionIntro,
    (TutorialLessonId.collision, 'collide') => l10n.tutorialCollisionCollide,
    (TutorialLessonId.collision, 'outro') => l10n.tutorialCollisionOutro,
    (TutorialLessonId.finalRound, 'intro') => l10n.tutorialFinalIntro,
    (TutorialLessonId.finalRound, 'noStop') => l10n.tutorialFinalNoStop,
    (TutorialLessonId.finalRound, 'exact') => l10n.tutorialFinalExact,
    (TutorialLessonId.finalRound, 'outro') => l10n.tutorialFinalOutro,
    _ => '',
  };
}

/// Les bulles du tutoriel, posées PAR-DESSUS l'écran de jeu : une bulle de
/// bande dessinée dont la queue part de l'élément montré, et qui ne laisse
/// passer le doigt que sur la commande à toucher — tout le reste est inerte,
/// pour qu'on ne puisse pas sortir du scénario.
///
/// L'écran de jeu en pose une sur lui-même ([inDialog] faux) et une dans chaque
/// fenêtre qu'il ouvre (craque, main héritée : [inDialog] vrai), car une
/// fenêtre est une route au-dessus de l'écran. Chacune ne montre que les
/// étapes qui la concernent.
///
/// Rien n'est affiché (et tout est inerte) tant que [visible] est faux — les
/// dés roulent encore — ou que l'élément visé n'est pas encore mesurable.
class TutorialOverlay extends StatefulWidget {
  final TutorialGuide guide;
  final TutorialBeat? beat;
  final bool visible;
  final bool inDialog;

  const TutorialOverlay({super.key, required this.guide, required this.beat, required this.visible, this.inDialog = false});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  /// Où se trouve l'élément visé, dans le repère de cette superposition, et
  /// lequel : une mesure faite pour l'étape précédente ne vaut rien pour
  /// celle-ci.
  Rect? _measured;
  TutorialTarget? _measuredFor;

  Rect? get _target => _measuredFor == widget.beat?.target ? _measured : null;

  /// L'étape dont l'élément a déjà été amené à l'écran (voir [_measureAfterLayout]).
  TutorialBeat? _scrolledFor;

  static const _bubbleMaxWidth = 340.0;
  static const _tail = 10.0;
  static const _gap = 6.0;

  /// Mesure l'élément visé après chaque construction : l'écran défile, se
  /// redimensionne et intervertit ses commandes selon la latéralité, rien de
  /// tout cela n'est connu d'avance.
  void _measureAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final beat = widget.beat;
      final target = beat?.target;
      Rect? measured;
      if (target != null) {
        final targetContext = widget.guide.keyFor(target).currentContext;
        // L'écran défile : sur un petit téléphone, la commande visée peut être
        // cachée sous la barre du bas. On l'amène à l'écran, une fois par étape.
        if (targetContext != null && !identical(_scrolledFor, beat) && target.inDialog == widget.inDialog) {
          _scrolledFor = beat;
          Scrollable.ensureVisible(targetContext, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
          Scrollable.ensureVisible(targetContext, alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart);
        }
        final box = targetContext?.findRenderObject();
        final mine = context.findRenderObject();
        if (box is RenderBox && box.attached && box.hasSize && mine is RenderBox) {
          measured = mine.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
        }
      }
      if (measured != _measured || target != _measuredFor) {
        setState(() {
          _measured = measured;
          _measuredFor = target;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _measureAfterLayout();
    final l10n = AppLocalizations.of(context);
    final beat = widget.beat;
    final target = beat?.target;
    // Une étape de fenêtre ne se montre que dans la fenêtre, les autres que
    // sur l'écran.
    final mine = beat != null && (target?.inDialog ?? false) == widget.inDialog;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final actionable = mine && target != null && !beat.needsAck && widget.visible;
    final hole = actionable ? _target?.inflate(6) : null;

    Widget absorber({required double left, required double top, required double right, required double bottom}) =>
        Positioned(
          left: left,
          top: top,
          right: right,
          bottom: bottom,
          child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}, child: const SizedBox.expand()),
        );

    final text = beat == null ? '' : tutorialBeatText(l10n, widget.guide.lesson.id, beat.id);
    final showBubble = mine && widget.visible && text.isNotEmpty && (target == null || _target != null);
    final button = beat == null || !beat.needsAck
        ? null
        : beat.isOutro
        ? (widget.guide.hasNext ? l10n.tutorialNextLesson : l10n.tutorialFinish)
        : l10n.tutorialNext;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hole == null)
          absorber(left: 0, top: 0, right: 0, bottom: 0)
        else ...[
          absorber(left: 0, top: 0, right: 0, bottom: size.height - hole.top),
          absorber(left: 0, top: hole.bottom, right: 0, bottom: 0),
          absorber(left: 0, top: hole.top, right: size.width - hole.left, bottom: size.height - hole.bottom),
          absorber(left: hole.right, top: hole.top, right: 0, bottom: size.height - hole.bottom),
        ],
        if (showBubble)
          if (target == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _bubble(context, text, beat, tailX: null, tailUp: false, button: button),
              ),
            )
          else
            _anchoredBubble(context, text, beat, _target!, size, button),
        if (!(beat?.isOutro ?? false))
          Positioned(
            top: padding.top + 4,
            right: 8,
            child: TextButton(onPressed: widget.guide.onExit, child: Text(l10n.tutorialSkip)),
          ),
      ],
    );
  }

  /// La bulle d'un élément : sous lui quand il y a la place, sinon au-dessus ;
  /// la queue part de son centre.
  Widget _anchoredBubble(BuildContext context, String text, TutorialBeat beat, Rect target, Size screen, String? button) {
    final width = (screen.width - 32).clamp(0.0, _bubbleMaxWidth);
    final left = (target.center.dx - width / 2).clamp(16.0, screen.width - 16 - width);
    final below = screen.height - target.bottom > 220;
    final tailX = (target.center.dx - left).clamp(24.0, width - 24);
    final bubble = SizedBox(
      width: width,
      child: _bubble(context, text, beat, tailX: tailX, tailUp: below, button: button),
    );
    return below
        ? Positioned(left: left, top: target.bottom + _gap, child: bubble)
        : Positioned(left: left, bottom: screen.height - target.top + _gap, child: bubble);
  }

  Widget _bubble(
    BuildContext context,
    String text,
    TutorialBeat beat, {
    required double? tailX,
    required bool tailUp,
    required String? button,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final body = Material(
      color: scheme.primaryContainer,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              text,
              key: const ValueKey('tutorial-text'),
              style: TextStyle(fontSize: 15, height: 1.35, color: scheme.onPrimaryContainer),
            ),
            if (button != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('tutorial-action'),
                onPressed: () => widget.guide.press(beat),
                child: Text(button),
              ),
            ],
          ],
        ),
      ),
    );
    if (tailX == null) {
      return ConstrainedBox(constraints: const BoxConstraints(maxWidth: _bubbleMaxWidth), child: body);
    }
    final tail = Padding(
      padding: EdgeInsets.only(left: tailX - _tail),
      child: CustomPaint(
        size: const Size(_tail * 2, _tail),
        painter: _TailPainter(scheme.primaryContainer, up: tailUp),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tailUp ? [tail, body] : [body, tail],
    );
  }
}

/// Les bulles du tutoriel dans une fenêtre de l'écran de jeu (craque, main
/// héritée) : [child], la fenêtre, avec par-dessus la superposition des étapes
/// qui la concernent. Suit la partie et le guide d'elle-même — une fenêtre ne
/// se reconstruit pas avec l'écran qui l'a ouverte.
class TutorialDialogLayer extends ConsumerWidget {
  final TutorialGuide guide;
  final Widget child;

  const TutorialDialogLayer({super.key, required this.guide, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(gameProvider);
    return ListenableBuilder(
      listenable: guide,
      builder: (context, _) => Stack(
        children: [
          child,
          if (engine != null)
            Positioned.fill(
              child: TutorialOverlay(guide: guide, beat: guide.beatFor(engine), visible: true, inDialog: true),
            ),
        ],
      ),
    );
  }
}

/// La queue d'une bulle : un triangle, pointe en haut ([up]) ou en bas.
class _TailPainter extends CustomPainter {
  final Color color;
  final bool up;

  const _TailPainter(this.color, {required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final path = up
        ? (Path()
            ..moveTo(0, size.height)
            ..lineTo(size.width / 2, 0)
            ..lineTo(size.width, size.height))
        : (Path()
            ..moveTo(0, 0)
            ..lineTo(size.width / 2, size.height)
            ..lineTo(size.width, 0));
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color || old.up != up;
}
