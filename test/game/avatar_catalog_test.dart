import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/avatar_catalog.dart';

void main() {
  test('les identifiants de couleurs et d\'animaux sont uniques', () {
    expect(avatarColorChoices.map((c) => c.id).toSet().length, avatarColorChoices.length);
    expect(avatarAnimalChoices.map((a) => a.id).toSet().length, avatarAnimalChoices.length);
    expect(avatarColorChoices.map((c) => c.argb).toSet().length, avatarColorChoices.length,
        reason: 'deux couleurs identiques ne se distingueraient pas');
  });

  test('chaque couleur est opaque', () {
    for (final c in avatarColorChoices) {
      expect(c.argb >> 24, 0xFF, reason: c.id);
    }
  });

  test('un identifiant se retrouve ; un inconnu ou nul donne null', () {
    expect(avatarColorById('teal')?.id, 'teal');
    expect(avatarAnimalById('fox')?.emoji, '🦊');
    expect(avatarColorById('mauve-fluo'), isNull);
    expect(avatarAnimalById(null), isNull);
  });

  test('isKnown… dit ce que le serveur relaie', () {
    expect(isKnownAvatarColorId('brick'), isTrue);
    expect(isKnownAvatarAnimalId('dog'), isTrue);
    expect(isKnownAvatarColorId('nope'), isFalse);
    expect(isKnownAvatarAnimalId('<script>'), isFalse);
  });
}
