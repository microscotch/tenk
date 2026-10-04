import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/theme.dart';
import 'package:le10000/ui/widgets/casino_felt_background.dart';

/// Pendant le glissé d'un écran à l'autre, le feutre de table ne doit pas bouger
/// avec la page : sinon la vignette (bords assombris) et le dégradé balaient
/// l'écran, et le fond paraît terne le temps du passage.
void main() {
  final shot = GlobalKey();

  Future<Uint8List> capture(WidgetTester tester) async {
    final boundary = shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    return (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      return bytes!.buffer.asUint8List();
    }))!;
  }

  /// L'écart moyen par canal entre deux captures, sur la bande du milieu de
  /// l'écran (loin des bords où se dessine l'ombre portée de la page).
  double meanDifference(Uint8List a, Uint8List b, int width, int height) {
    var total = 0;
    var count = 0;
    for (var y = height ~/ 3; y < 2 * height ~/ 3; y += 3) {
      for (var x = 0; x < width; x += 3) {
        final i = (y * width + x) * 4;
        for (var c = 0; c < 3; c++) {
          total += (a[i + c] - b[i + c]).abs();
          count++;
        }
      }
    }
    return total / count;
  }

  testWidgets('le feutre reste immobile pendant qu\'une page glisse par-dessus l\'autre', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(RepaintBoundary(
      key: shot,
      child: MaterialApp(
        navigatorKey: navigator,
        theme: buildAppTheme().copyWith(platform: TargetPlatform.android),
        // Comme l'app : le feutre derrière le navigateur, des écrans transparents.
        builder: (context, child) => Stack(children: [const CasinoFeltBackground(), ?child]),
        home: const Scaffold(),
      ),
    ));
    await tester.pumpAndSettle();
    final atRest = await capture(tester);

    navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final midway = await capture(tester);

    expect(meanDifference(atRest, midway, 400, 800), lessThan(0.5),
        reason: 'à mi-transition, le fond doit être celui de l\'écran au repos');
  });
}
