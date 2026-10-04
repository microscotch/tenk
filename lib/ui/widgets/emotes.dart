import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/online_providers.dart';

/// L'émoji d'une émotion : celui du système, pour être lu d'un coup d'œil.
String emoteEmoji(Emote emote) => switch (emote) {
      Emote.thoughtful => '🤔',
      Emote.mocking => '😏',
      Emote.devastated => '😭',
      Emote.joyful => '😄',
    };

/// Le nom d'une émotion, pour les lecteurs d'écran.
String emoteName(AppLocalizations l10n, Emote emote) => switch (emote) {
      Emote.thoughtful => l10n.emoteThoughtful,
      Emote.mocking => l10n.emoteMocking,
      Emote.devastated => l10n.emoteDevastated,
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

  const EmoteBar({super.key, required this.onSend});

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

  Future<void> _openPhrases(BuildContext buttonContext, Emote emote) async {
    if (_coolingDown) return;
    final l10n = AppLocalizations.of(context);
    final box = buttonContext.findRenderObject()! as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final phrase = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(origin & box.size, Offset.zero & overlay.size),
      items: [
        for (final phrase in emote.phrases)
          PopupMenuItem(value: phrase, child: Text(emotePhrase(l10n, phrase) ?? phrase)),
      ],
    );
    if (phrase != null && mounted) _send(emote, phrase);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final enabled = !_coolingDown;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final emote in Emote.values)
          Builder(
            builder: (buttonContext) => Semantics(
              button: true,
              enabled: enabled,
              label: emoteName(l10n, emote),
              excludeSemantics: true,
              child: InkResponse(
                onTap: enabled ? () => _send(emote, null) : null,
                onLongPress: enabled ? () => _openPhrases(buttonContext, emote) : null,
                radius: 28,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: enabled ? 1 : 0.35,
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                    ),
                    child: Text(emoteEmoji(emote), style: const TextStyle(fontSize: 26)),
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
