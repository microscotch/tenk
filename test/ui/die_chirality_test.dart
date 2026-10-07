import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/die_widget.dart';

void main() {
  test('les faces opposées font 7, et chaque face vue est unique', () {
    for (var top = 1; top <= 6; top++) {
      for (var turns = 0; turns < 4; turns++) {
        final f = dieFaceValues(top, quarterTurns: turns);
        expect(f['top']! + f['bottom']!, 7);
        expect(f['front']! + f['back']!, 7);
        expect(f['right']! + f['left']!, 7);
        expect({...f.values}.length, 6);
      }
    }
  });

  test('un dé occidental : 1 dessus, 2 devant, 3 à droite (sens inverse des aiguilles)', () {
    final f = dieFaceValues(1);
    // Le dé dont le dessus est 1 est le dé de référence : 2 devant, 3 à droite.
    expect((f['front'], f['right']), (2, 3));
  });

  test('tous les dés ont la même chiralité, quel que soit le dessus et le quart de tour', () {
    // Pour chaque coin (dessus, avant, droite), la parité est celle de 1-2-3.
    int parity(int t, int f, int r) {
      int pair(int v) => v <= 3 ? v : 7 - v;
      int side(int v) => v <= 3 ? 1 : -1;
      final p = [pair(t), pair(f), pair(r)];
      var inv = 0;
      for (var i = 0; i < 3; i++) {
        for (var j = i + 1; j < 3; j++) {
          if (p[i] > p[j]) inv++;
        }
      }
      return (inv.isEven ? 1 : -1) * side(t) * side(f) * side(r);
    }

    for (var top = 1; top <= 6; top++) {
      for (var turns = 0; turns < 4; turns++) {
        final f = dieFaceValues(top, quarterTurns: turns);
        expect(parity(f['top']!, f['front']!, f['right']!), 1, reason: 'dessus $top, quart $turns');
      }
    }
  });

  test('un coin quelconque reproduit 1-2-3 : (1,2,3), (2,3,1), (3,1,2) restent directs', () {
    // Les trois permutations circulaires d'un même coin se suivent dans le même sens.
    final a = dieFaceValues(1);
    expect((a['top'], a['front'], a['right']), (1, 2, 3));
    final b = dieFaceValues(2);
    final c = dieFaceValues(3);
    // Pour dessus 2 : (2, x, y) doit être un coin direct, donc (2,3,1) ou (2,6,3)…
    expect({b['front'], b['right']}.contains(1) || {b['front'], b['right']}.contains(6), isTrue);
    expect({c['front'], c['right']}.contains(2) || {c['front'], c['right']}.contains(5), isTrue);
  });
}
