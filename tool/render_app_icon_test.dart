// Régénère les deux PNG sources de l'icône de l'app (assets/icon/) : le dé du
// menu d'accueil, mais opaque, laiton, gravé « 10 » / « K » / un as.
//
//   flutter test tool/render_app_icon_test.dart
//   dart run flutter_launcher_icons
//
// Ce n'est pas un test de la suite (elle ne lit que test/) : c'est un outil, qui
// passe par flutter_test pour disposer du moteur de rendu sans écran. La police
// des chiffres, Fraunces (licence OFL), est dans tool/icon/ ; elle n'est pas
// embarquée dans l'app.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/menu_die.dart';

const _side = 1024.0;
const _brass = Color(0xFFD6A94A);
const _ink = Color(0xFF2A1E0C);

/// Marge minimale entre le dé et le bord de l'icône.
const _margin = 5.0;

Future<void> _write(String path, void Function(Canvas canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(_side.toInt(), _side.toInt());
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  File(path).writeAsBytesSync(bytes.buffer.asUint8List());
}

void main() {
  testWidgets('icône de l\'app', (tester) async {
    final font = FontLoader('Fraunces')..addFont(Future.value(ByteData.sublistView(File('tool/icon/Fraunces.ttf').readAsBytesSync())));
    await font.load();
    const numerals = TextStyle(
      fontFamily: 'Fraunces',
      fontVariations: [FontVariation('wght', 900), FontVariation('opsz', 144)],
    );

    void die(Canvas canvas, double width) {
      canvas.save();
      canvas.translate((_side - width) / 2, (_side - width) / 2);
      paintAppIconDie(canvas, Size(width, width), color: _brass, ink: _ink, numerals: numerals);
      canvas.restore();
    }

    await tester.runAsync(() async {
      // iOS et Android ancien : le dé au plus grand (marge de 5 px), sur fond
      // transparent (c'est flutter_launcher_icons qui l'aplatit sur iOS, voir
      // `background_color_ios`). Le fichier garde son ancien nom, `opaque`.
      await _write('assets/icon/app_icon_opaque.png', (canvas) => die(canvas, _side - 2 * _margin));
      // Android adaptatif : le dé seul sur fond transparent, resserré dans la zone
      // sûre (le lanceur masque le tour de l'icône ; tout ce qui dépasse est rogné).
      await _write('assets/icon/app_icon_foreground.png', (canvas) => die(canvas, 600));
    });
  });
}
