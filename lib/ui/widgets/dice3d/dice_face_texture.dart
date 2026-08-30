import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';

import '../die_widget.dart' show DieVisualState;

/// Positions (fraction of face size) of the pips for each face value,
/// matching a standard die layout.
const Map<int, List<Offset>> pipPositions = {
  1: [Offset(0.5, 0.5)],
  2: [Offset(0.25, 0.25), Offset(0.75, 0.75)],
  3: [Offset(0.25, 0.25), Offset(0.5, 0.5), Offset(0.75, 0.75)],
  4: [Offset(0.25, 0.25), Offset(0.75, 0.25), Offset(0.25, 0.75), Offset(0.75, 0.75)],
  5: [
    Offset(0.25, 0.25),
    Offset(0.75, 0.25),
    Offset(0.5, 0.5),
    Offset(0.25, 0.75),
    Offset(0.75, 0.75),
  ],
  6: [
    Offset(0.25, 0.2),
    Offset(0.75, 0.2),
    Offset(0.25, 0.5),
    Offset(0.75, 0.5),
    Offset(0.25, 0.8),
    Offset(0.75, 0.8),
  ],
};

/// Couleur du corps du dé (façon ivoire, comme un vrai dé en plastique),
/// légèrement teintée pour les 5 déclinés.
Color bodyColorFor(DieVisualState state) => switch (state) {
      DieVisualState.declined => const Color(0xFFFBEEDD),
      _ => const Color(0xFFF7F2E7),
    };

/// Couleur du liseré fin qui porte le signal d'état (gardé/junk/décliné/
/// étendu), volontairement discret pour ne pas casser l'aspect "vrai dé".
Color accentColorFor(DieVisualState state) => switch (state) {
      DieVisualState.kept => Colors.green.shade600,
      DieVisualState.junk => Colors.blueGrey.shade200,
      DieVisualState.declined => Colors.orange.shade700,
      DieVisualState.extended => Colors.red.shade600,
    };

/// Couleur des pips : noir classique, sauf pour un dé étendu où ils reprennent
/// la couleur d'accent pour rester bien visibles.
Color pipColorFor(DieVisualState state) =>
    state == DieVisualState.extended ? Colors.red.shade700 : const Color(0xFF2A2118);

/// Renders one die face (background + border + pips) to a texture usable by
/// a [PhysicallyBasedMaterial], and caches the result: the same (value,
/// state) pair is reused across every die and every face that needs it,
/// since the drawing only depends on those two inputs.
class DiceFaceTextures {
  DiceFaceTextures._();

  static const _size = 128.0;
  static final Map<String, Future<Texture2D>> _cache = {};

  static Future<Texture2D> get(int value, DieVisualState state) {
    final key = '$value|$state';
    return _cache.putIfAbsent(key, () => _render(value, state));
  }

  static Future<Texture2D> _render(int value, DieVisualState state) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, _size, _size));
    final body = bodyColorFor(state);
    final accent = accentColorFor(state);
    final pipColor = pipColorFor(state);

    final rrect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 3, _size - 6, _size - 6),
      const Radius.circular(_size * 0.2),
    );

    // Corps du dé : léger dégradé façon plastique moulé plutôt qu'un aplat.
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(_size, _size),
          [body, Color.lerp(body, Colors.black, 0.05)!],
        ),
    );

    // Liseré fin de couleur d'état, en retrait du bord pour rester discret.
    canvas.drawRRect(
      rrect.deflate(_size * 0.02),
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = _size * 0.035,
    );

    // Pips légèrement "gravés" : une ombre portée, le disque, un reflet.
    for (final p in pipPositions[value] ?? const []) {
      final center = Offset(p.dx * _size, p.dy * _size);
      final radius = _size * 0.078;
      canvas.drawCircle(
        center + Offset(_size * 0.006, _size * 0.01),
        radius,
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );
      canvas.drawCircle(center, radius, Paint()..color = pipColor);
      canvas.drawCircle(
        center - Offset(radius * 0.3, radius * 0.3),
        radius * 0.35,
        Paint()..color = Colors.white.withValues(alpha: 0.25),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(_size.toInt(), _size.toInt());
    try {
      return await Texture2D.fromImage(image);
    } finally {
      image.dispose();
    }
  }
}
