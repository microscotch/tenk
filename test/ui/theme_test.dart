import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/theme.dart';

void main() {
  test('seul iOS voit ses polices réduites', () {
    expect(textScaleFactorFor(TargetPlatform.iOS), lessThan(1));
    expect(textScaleFactorFor(TargetPlatform.android), 1);
    expect(textScaleFactorFor(TargetPlatform.linux), 1);
  });

  testWidgets('sur iOS, la taille de texte du système est réduite du facteur, pas remplacée', (tester) async {
    late double scale;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Builder(
            builder: (context) => withPlatformTextScale(
              context,
              Builder(
                builder: (context) {
                  scale = MediaQuery.textScalerOf(context).scale(10) / 10;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(scale, closeTo(1.5 * iosTextScaleFactor, 1e-9));
  });
}
