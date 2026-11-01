import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/state/konami_code.dart';

void main() {
  final start = DateTime(2026, 11, 1, 12);

  /// Joue [keys] à [gap] d'intervalle, depuis [from] ; vrai si l'un d'eux achève le code.
  bool play(KonamiDetector d, List<KonamiKey> keys, {Duration gap = const Duration(milliseconds: 500), DateTime? from}) {
    var detected = false;
    var t = from ?? start;
    for (final key in keys) {
      detected = d.press(key, t) || detected;
      t = t.add(gap);
    }
    return detected;
  }

  test('le code complet, saisi assez vite, est reconnu à son dernier appui', () {
    final d = KonamiDetector();
    expect(play(d, KonamiDetector.code), isTrue);
  });

  test('le code est détecté exactement sur Start, pas avant', () {
    final d = KonamiDetector();
    final early = play(d, KonamiDetector.code.sublist(0, 10));
    expect(early, isFalse);
    expect(d.press(KonamiKey.start, start.add(const Duration(seconds: 6))), isTrue);
  });

  test('trop lent : le code n\'est pas reconnu', () {
    final d = KonamiDetector();
    expect(play(d, KonamiDetector.code, gap: const Duration(seconds: 2)), isFalse);
  });

  test('à la limite de la fenêtre il passe, au-delà non', () {
    final d = KonamiDetector(window: const Duration(seconds: 5));
    expect(play(d, KonamiDetector.code, gap: const Duration(milliseconds: 500)), isTrue); // 5 s pile
    expect(play(d, KonamiDetector.code, gap: const Duration(milliseconds: 501)), isFalse);
  });

  test('une touche fausse au milieu le casse ; il faut tout reprendre', () {
    final d = KonamiDetector();
    final wrong = [...KonamiDetector.code]..[4] = KonamiKey.right;
    expect(play(d, wrong), isFalse);
  });

  test('des appuis parasites avant le code ne l\'empêchent pas', () {
    final d = KonamiDetector();
    expect(play(d, [KonamiKey.a, KonamiKey.up, KonamiKey.b, ...KonamiDetector.code]), isTrue);
  });

  test('après une détection le compteur repart de zéro', () {
    final d = KonamiDetector();
    expect(play(d, KonamiDetector.code), isTrue);
    expect(d.press(KonamiKey.start, start.add(const Duration(seconds: 7))), isFalse);
  });
}
