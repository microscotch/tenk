import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/sound_effects.dart';

void main() {
  group('bruit d\'un lancer de dés', () {
    test('chaque prise annoncée existe dans les assets, et il n\'y en a pas d\'autre', () {
      final expected = {
        for (final MapEntry(key: dice, value: takes) in diceRollTakes.entries)
          for (var k = 1; k <= takes; k++) 'dice_roll_${dice}_${k.toString().padLeft(2, '0')}.wav',
      };
      final present = Directory('assets/sounds')
          .listSync()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.startsWith('dice_roll'))
          .toSet();
      expect(present, expected);
    });

    test('la prise correspond au nombre de dés lancés', () {
      final random = Random(1);
      for (var dice = 1; dice <= 5; dice++) {
        for (var i = 0; i < 30; i++) {
          expect(diceRollAsset(dice, random), startsWith('sounds/dice_roll_${dice}_'));
        }
      }
    });

    test('toutes les prises finissent par sortir', () {
      final random = Random(2);
      final seen = {for (var i = 0; i < 400; i++) diceRollAsset(3, random)};
      expect(seen, hasLength(diceRollTakes[3]));
    });

    test('deux lancers de suite ne sonnent jamais pareil', () {
      final random = Random(3);
      String? previous;
      for (var i = 0; i < 200; i++) {
        final asset = diceRollAsset(4, random, avoid: previous);
        expect(asset, isNot(previous));
        previous = asset;
      }
    });

    test('au-delà de 5 dés (tirage au sort à 6), une prise de 5 ; en deçà de 1, une prise de 1', () {
      expect(diceRollAsset(6, Random(4)), startsWith('sounds/dice_roll_5_'));
      expect(diceRollAsset(0, Random(4)), startsWith('sounds/dice_roll_1_'));
    });
  });
}
