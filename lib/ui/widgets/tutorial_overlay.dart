import 'package:flutter/material.dart';

import '../../game/tutorial.dart';
import '../../l10n/generated/app_localizations.dart';

/// Ce que l'écran de jeu doit au tutoriel : une clé par commande qu'une bulle
/// peut montrer (posées sur les vraies commandes, voir `GameScreen`), et la
/// sortie du tutoriel — « Passer » comme « Commencer à jouer » y mènent.
class TutorialGuide {
  final GlobalKey rollKey = GlobalKey(debugLabel: 'tutorial-roll');
  final GlobalKey exchangeKey = GlobalKey(debugLabel: 'tutorial-exchange');
  final GlobalKey stopKey = GlobalKey(debugLabel: 'tutorial-stop');

  /// Quitte le tutoriel (fini ou passé).
  final VoidCallback onExit;

  TutorialGuide({required this.onExit});

  GlobalKey keyFor(TutorialTarget target) => switch (target) {
    TutorialTarget.roll => rollKey,
    TutorialTarget.exchange => exchangeKey,
    TutorialTarget.stop => stopKey,
  };
}

/// Le texte d'une étape.
String tutorialStepText(AppLocalizations l10n, TutorialStep step) =>
    switch (step) {
      TutorialStep.intro => l10n.tutorialStep0,
      TutorialStep.rollFirst => l10n.tutorialStep1,
      TutorialStep.rollAgain => l10n.tutorialStep2,
      TutorialStep.hotDice => l10n.tutorialStep3,
      TutorialStep.exchange => l10n.tutorialStep4,
      TutorialStep.stop => l10n.tutorialStep5,
      TutorialStep.outro => l10n.tutorialStep6,
      TutorialStep.waiting => '',
    };

/// Les bulles du tutoriel, posées PAR-DESSUS le vrai écran de jeu : une bulle
/// de bande dessinée dont la queue part de la commande à toucher, et qui laisse
/// passer le doigt sur cette seule commande — tout le reste de l'écran est
/// inerte, pour qu'on ne puisse pas sortir du scénario.
///
/// Rien n'est affiché (et tout est inerte) tant que [visible] est faux — les
/// dés roulent encore — ou que la commande visée n'est pas encore mesurable.
class TutorialOverlay extends StatefulWidget {
  final TutorialGuide guide;
  final TutorialStep step;
  final bool visible;

  /// « Suivant » de l'accueil.
  final VoidCallback onNext;

  const TutorialOverlay({
    super.key,
    required this.guide,
    required this.step,
    required this.visible,
    required this.onNext,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  /// Où se trouve la commande visée, dans le repère de cette superposition.
  Rect? _target;

  static const _bubbleMaxWidth = 340.0;
  static const _tail = 10.0;
  static const _gap = 6.0;

  /// Mesure la commande visée après chaque construction : l'écran de jeu défile,
  /// se redimensionne et intervertit ses commandes selon la latéralité, rien
  /// de tout cela n'est connu d'avance.
  void _measureAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = widget.step.target;
      Rect? measured;
      if (target != null) {
        final box = widget.guide
            .keyFor(target)
            .currentContext
            ?.findRenderObject();
        final mine = context.findRenderObject();
        if (box is RenderBox &&
            box.attached &&
            box.hasSize &&
            mine is RenderBox) {
          measured =
              mine.globalToLocal(box.localToGlobal(Offset.zero)) & box.size;
        }
      }
      if (measured != _target) setState(() => _target = measured);
    });
  }

  @override
  Widget build(BuildContext context) {
    _measureAfterLayout();
    final l10n = AppLocalizations.of(context);
    final step = widget.step;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final hole = (step.target != null && widget.visible)
        ? _target?.inflate(6)
        : null;

    Widget absorber({
      required double left,
      required double top,
      required double right,
      required double bottom,
    }) => Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: const SizedBox.expand(),
      ),
    );

    final text = tutorialStepText(l10n, step);
    final showBubble =
        widget.visible &&
        text.isNotEmpty &&
        (step.target == null || _target != null);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hole == null)
          absorber(left: 0, top: 0, right: 0, bottom: 0)
        else ...[
          absorber(left: 0, top: 0, right: 0, bottom: size.height - hole.top),
          absorber(left: 0, top: hole.bottom, right: 0, bottom: 0),
          absorber(
            left: 0,
            top: hole.top,
            right: size.width - hole.left,
            bottom: size.height - hole.bottom,
          ),
          absorber(
            left: hole.right,
            top: hole.top,
            right: 0,
            bottom: size.height - hole.bottom,
          ),
        ],
        if (showBubble)
          if (step.target == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _bubble(
                  context,
                  text,
                  tailX: null,
                  tailUp: false,
                  button: step == TutorialStep.intro
                      ? l10n.tutorialNext
                      : l10n.tutorialFinish,
                ),
              ),
            )
          else
            _anchoredBubble(context, text, _target!, size),
        if (step != TutorialStep.outro)
          Positioned(
            top: padding.top + 4,
            right: 8,
            child: TextButton(
              onPressed: widget.guide.onExit,
              child: Text(l10n.tutorialSkip),
            ),
          ),
      ],
    );
  }

  /// La bulle d'une commande : sous elle quand il y a la place (c'est le journal
  /// qui est alors recouvert, rien d'important), sinon au-dessus ; la queue part
  /// du centre de la commande.
  Widget _anchoredBubble(
    BuildContext context,
    String text,
    Rect target,
    Size screen,
  ) {
    final width = (screen.width - 32).clamp(0.0, _bubbleMaxWidth);
    final left = (target.center.dx - width / 2).clamp(
      16.0,
      screen.width - 16 - width,
    );
    final below = screen.height - target.bottom > 200;
    final tailX = (target.center.dx - left).clamp(24.0, width - 24);
    final bubble = SizedBox(
      width: width,
      child: _bubble(context, text, tailX: tailX, tailUp: below, button: null),
    );
    return below
        ? Positioned(left: left, top: target.bottom + _gap, child: bubble)
        : Positioned(
            left: left,
            bottom: screen.height - target.top + _gap,
            child: bubble,
          );
  }

  Widget _bubble(
    BuildContext context,
    String text, {
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
              style: TextStyle(
                fontSize: 15,
                height: 1.35,
                color: scheme.onPrimaryContainer,
              ),
            ),
            if (button != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('tutorial-action'),
                onPressed: widget.step == TutorialStep.intro
                    ? widget.onNext
                    : widget.guide.onExit,
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
