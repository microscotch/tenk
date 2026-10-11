import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/online/emotes.dart';

void main() {
  test('la première série ne propose ni Fâché ni Soulagé, ni les phrases ajoutées', () {
    expect(emotesFor(v2: false), [Emote.thoughtful, Emote.mocking, Emote.devastated, Emote.joyful]);
    expect(emotesFor(v2: true), Emote.values);
    expect(Emote.devastated.phrasesFor(v2: false), ['noWay', 'coincidence', 'lucky', 'argh']);
    expect(Emote.devastated.phrasesFor(v2: true), ['noWay', 'unfair', 'argh']);
    expect(Emote.thoughtful.phrasesFor(v2: false), isNot(contains('strangeChoice')));
  });

  test('les phrases passées chez Fâché restent acceptées sous Dévasté', () {
    expect(Emote.devastated.accepts('coincidence'), isTrue);
    expect(Emote.devastated.accepts('lucky'), isTrue);
    expect(Emote.angry.accepts('coincidence'), isTrue);
    expect(Emote.angry.accepts('noWay'), isFalse);
  });

  test('ce qui part vers un client de la première série', () {
    expect(downgradeForV1(Emote.mocking, 'tooGreedy'), (Emote.mocking, 'tooGreedy'));
    expect(downgradeForV1(Emote.angry, 'lucky'), (Emote.devastated, 'lucky'));
    expect(downgradeForV1(Emote.mocking, 'withPanache'), (Emote.mocking, null), reason: 'phrase nouvelle : l\'émotion seule');
    expect(downgradeForV1(Emote.angry, null), isNull);
    expect(downgradeForV1(Emote.relieved, 'phew'), isNull);
  });

  test('toute phrase proposée a un texte, et tout ce que la première série accepte est encore accepté', () {
    for (final emote in Emote.values) {
      for (final phrase in emote.phrases) {
        expect(emote.accepts(phrase), isTrue);
      }
    }
    emotesV1.forEach((emote, phrases) {
      for (final phrase in phrases) {
        expect(emote.accepts(phrase), isTrue, reason: '${emote.name}/$phrase');
      }
    });
  });
}
