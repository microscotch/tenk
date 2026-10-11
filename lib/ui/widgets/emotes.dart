import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/online_providers.dart';

/// L'émoji d'une émotion : celui du système, pour être lu d'un coup d'œil.
String emoteEmoji(Emote emote) => switch (emote) {
      Emote.thoughtful => '🤔',
      Emote.mocking => '🤣',
      Emote.devastated => '😭',
      Emote.angry => '😠',
      Emote.relieved => '😌',
      Emote.joyful => '🤗',
    };

/// Le nom d'une émotion, pour les lecteurs d'écran.
String emoteName(AppLocalizations l10n, Emote emote) => switch (emote) {
      Emote.thoughtful => l10n.emoteThoughtful,
      Emote.mocking => l10n.emoteMocking,
      Emote.devastated => l10n.emoteDevastated,
      Emote.angry => l10n.emoteAngry,
      Emote.relieved => l10n.emoteRelieved,
      Emote.joyful => l10n.emoteJoyful,
    };

/// Une phrase d'émotion, dans la langue de l'appareil ; null pour un
/// identifiant inconnu (une version plus récente).
String? emotePhrase(AppLocalizations l10n, String phrase) => switch (phrase) {
      'coincidence' => l10n.emotePhraseCoincidence,
      'stickyFive' => l10n.emotePhraseStickyFive,
      'fullHandEmptyHand' => l10n.emotePhraseFullHandEmptyHand,
      'neverTakeA1000' => l10n.emotePhraseNeverTakeA1000,
      'noWay' => l10n.emotePhraseNoWay,
      'argh' => l10n.emotePhraseArgh,
      'hello' => l10n.emotePhraseHello,
      'yes' => l10n.emotePhraseYes,
      'tooGreedy' => l10n.emotePhraseTooGreedy,
      'tooLucky' => l10n.emotePhraseTooLucky,
      'dryTenThousand' => l10n.emotePhraseDryTenThousand,
      'lucky' => l10n.emotePhraseLucky,
      'goodLuck' => l10n.emotePhraseGoodLuck,
      'thanks' => l10n.emotePhraseThanks,
      'sorryMustGo' => l10n.emotePhraseSorryMustGo,
      'strangeChoice' => l10n.emotePhraseStrangeChoice,
      'allByFives' => l10n.emotePhraseAllByFives,
      'withPanache' => l10n.emotePhraseWithPanache,
      'unfair' => l10n.emotePhraseUnfair,
      'phew' => l10n.emotePhrasePhew,
      'atLast' => l10n.emotePhraseAtLast,
      'closeCall' => l10n.emotePhraseCloseCall,
      'wellPlayed' => l10n.emotePhraseWellPlayed,
      'sorry' => l10n.emotePhraseSorry,
      _ => null,
    };

/// Ce que montre une émotion reçue : sa phrase quand il y en a une, à la place
/// de l'émoji ; l'émoji sinon.
String emoteText(AppLocalizations l10n, Emote emote, String? phrase) =>
    (phrase == null ? null : emotePhrase(l10n, phrase)) ?? emoteEmoji(emote);

/// Les boutons d'émotion d'une partie en ligne : un tap envoie l'émoji, un appui
/// long ouvre le menu des phrases de cette émotion. Après un envoi, tous
/// restent grisés [emoteCooldown] durant — le serveur ignorerait ce qui part
/// plus tôt.
class EmoteBar extends StatefulWidget {
  final void Function(Emote emote, String? phrase) onSend;

  /// Vrai quand le serveur connaît la seconde série d'émotions (voir
  /// [emotes2Feature]) : sans elle, seules la première série et ses phrases
  /// d'alors sont proposées — un serveur d'avant refuserait le reste.
  final bool v2;

  const EmoteBar({super.key, required this.onSend, this.v2 = false});

  @override
  State<EmoteBar> createState() => _EmoteBarState();
}

class _EmoteBarState extends State<EmoteBar> {
  Timer? _cooldown;

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  bool get _coolingDown => _cooldown?.isActive ?? false;

  void _send(Emote emote, String? phrase) {
    if (_coolingDown) return;
    widget.onSend(emote, phrase);
    setState(() => _cooldown = Timer(emoteCooldown, () {
          if (mounted) setState(() {});
        }));
  }

  /// Ouvre les phrases de [emote] dans une bulle de bande dessinée posée
  /// au-dessus de son bouton, la pointe vers lui (voir [_PhraseBubbleRoute]).
  Future<void> _openPhrases(BuildContext buttonContext, Emote emote) async {
    if (_coolingDown) return;
    final l10n = AppLocalizations.of(context);
    final box = buttonContext.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    final phrase = await navigator.push<String>(_PhraseBubbleRoute(
      anchor: anchor,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      phrases: [
        for (final id in emote.phrasesFor(v2: widget.v2)) (id: id, text: emotePhrase(l10n, id) ?? id),
      ],
    ));
    if (phrase != null && mounted) _send(emote, phrase);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = !_coolingDown;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final emote in emotesFor(v2: widget.v2))
          Builder(
            builder: (buttonContext) => Semantics(
              button: true,
              enabled: enabled,
              label: emoteName(l10n, emote),
              excludeSemantics: true,
              child: InkResponse(
                onTap: enabled ? () => _send(emote, null) : null,
                onLongPress: enabled ? () => _openPhrases(buttonContext, emote) : null,
                radius: 25,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: enabled ? 1 : 0.35,
                  child: Container(
                    // Six boutons tiennent sur un écran de 360 points de large.
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(emoteEmoji(emote), style: const TextStyle(fontSize: 23)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Une bulle de bande dessinée, sa pointe à gauche vers le blason du joueur
/// qui parle. Le texte passe à la ligne plutôt que d'être tronqué ; corps et
/// pointe forment un seul contour, sans raccord visible.
class SpeechBubble extends StatelessWidget {
  final String text;

  const SpeechBubble({super.key, required this.text});

  static const _paper = Color(0xFFFFFBF0);
  static const _ink = Color(0xFF2A2116);
  static const _outline = Color(0xFF8A6A2E);

  /// La longueur de la pointe, du bord du corps à son extrémité.
  static const tail = 14.0;

  @override
  Widget build(BuildContext context) {
    // Un émoji seul (l'émotion sans phrase) se lit en plus grand.
    final emojiOnly = text.runes.length <= 2;
    return CustomPaint(
      painter: const _BubblePainter(fill: _paper, outline: _outline, tail: tail),
      child: Padding(
        padding: EdgeInsets.fromLTRB(tail + 10, emojiOnly ? 2 : 6, 12, emojiOnly ? 2 : 6),
        child: Text(
          text,
          softWrap: true,
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700, fontSize: emojiOnly ? 22 : 14, height: 1.25),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final Color fill;
  final Color outline;
  final double tail;

  const _BubblePainter({required this.fill, required this.outline, required this.tail});

  /// Le contour : le corps arrondi et sa pointe, réunis en une seule forme.
  Path _shape(Size size) {
    const radius = 14.0;
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(tail, 0, size.width, size.height), const Radius.circular(radius)));
    // La pointe part du milieu du bord gauche, assez large à la base pour se
    // fondre dans le corps, et se termine en pointe vers le blason.
    final middle = size.height / 2;
    final halfBase = (size.height / 2 - 3).clamp(6.0, 11.0);
    // Deux courbes creusées vers l'intérieur, qui se rejoignent en une pointe
    // nette juste à côté du blason : la pointe d'une bulle de bande dessinée.
    final pointer = Path()
      ..moveTo(tail + radius, middle - halfBase)
      ..quadraticBezierTo(tail * 0.55, middle - halfBase * 0.25, 0, middle + 3)
      ..quadraticBezierTo(tail * 0.75, middle + halfBase * 0.55, tail + radius, middle + halfBase)
      ..close();
    return Path.combine(PathOperation.union, body, pointer);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);
    canvas.drawShadow(shape, Colors.black, 4, false);
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.fill != fill || old.outline != outline || old.tail != tail;
}

/// Les phrases d'une émotion, dans une bulle de bande dessinée posée au-dessus
/// du bouton qui l'ouvre ([anchor], dans le repère de la page), sa pointe vers
/// lui. Un tap sur une phrase la rend ; un tap à côté, ou le retour système,
/// referme la bulle sans rien rendre.
class _PhraseBubbleRoute extends PopupRoute<String> {
  final Rect anchor;
  final List<({String id, String text})> phrases;

  @override
  final String barrierLabel;

  _PhraseBubbleRoute({required this.anchor, required this.phrases, required this.barrierLabel});

  static const _margin = 8.0;
  static const _maxWidth = 280.0;

  @override
  Color? get barrierColor => Colors.black26;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width - 2 * _margin).clamp(0.0, _maxWidth);
    final left = (anchor.center.dx - width / 2).clamp(_margin, screen.width - _margin - width);
    final tailX = (anchor.center.dx - left).clamp(24.0, width - 24.0);
    return Stack(
      children: [
        Positioned(
          left: left,
          bottom: screen.height - anchor.top + 2,
          width: width,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            alignment: Alignment(((tailX / width) * 2) - 1, 1),
            child: CustomPaint(
              painter: _DownBubblePainter(
                fill: SpeechBubble._paper,
                outline: SpeechBubble._outline,
                tail: SpeechBubble.tail,
                tailX: tailX,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, SpeechBubble.tail + 6),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final phrase in phrases)
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.of(context).pop(phrase.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            child: Text(
                              phrase.text,
                              style: const TextStyle(color: SpeechBubble._ink, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// La bulle des phrases : le même papier et le même trait que [SpeechBubble],
/// mais la pointe en bas, à [tailX] du bord gauche, vers le bouton.
class _DownBubblePainter extends CustomPainter {
  final Color fill;
  final Color outline;
  final double tail;
  final double tailX;

  const _DownBubblePainter({required this.fill, required this.outline, required this.tail, required this.tailX});

  Path _shape(Size size) {
    const radius = 14.0;
    final bottom = size.height - tail;
    final body = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTRB(0, 0, size.width, bottom), const Radius.circular(radius)));
    const halfBase = 11.0;
    final pointer = Path()
      ..moveTo(tailX - halfBase, bottom - radius)
      ..quadraticBezierTo(tailX - halfBase * 0.25, bottom + tail * 0.45, tailX + 3, size.height)
      ..quadraticBezierTo(tailX + halfBase * 0.55, bottom + tail * 0.25, tailX + halfBase, bottom - radius)
      ..close();
    return Path.combine(PathOperation.union, body, pointer);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final shape = _shape(size);
    canvas.drawShadow(shape, Colors.black, 4, false);
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..color = outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(_DownBubblePainter old) =>
      old.fill != fill || old.outline != outline || old.tail != tail || old.tailX != tailX;
}
