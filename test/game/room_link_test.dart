import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/online/room_link.dart';

void main() {
  group('roomLinkFor', () {
    test('donne le lien https du salon, code en majuscules', () {
      expect(roomLinkFor('ABCDE').toString(), 'https://tenk.microscotch.net/j/ABCDE');
      expect(roomLinkFor('abcde').toString(), 'https://tenk.microscotch.net/j/ABCDE');
    });

    test('le lien produit se relit', () {
      expect(parseRoomLink(roomLinkFor('K7M2P')), 'K7M2P');
    });
  });

  group('parseRoomLink', () {
    String? parse(String url) => parseRoomLink(Uri.parse(url));

    test('lit le code d\'un lien d\'invitation', () {
      expect(parse('https://tenk.microscotch.net/j/ABCDE'), 'ABCDE');
    });

    test('accepte les minuscules, un / final, une requête et un fragment', () {
      expect(parse('https://tenk.microscotch.net/j/abcde'), 'ABCDE');
      expect(parse('https://tenk.microscotch.net/j/ABCDE/'), 'ABCDE');
      expect(parse('https://tenk.microscotch.net/j/ABCDE?utm=x#top'), 'ABCDE');
      expect(parse('https://TENK.microscotch.net/j/ABCDE'), 'ABCDE');
    });

    test('refuse un autre hôte, même avec le bon chemin', () {
      expect(parse('https://example.com/j/ABCDE'), isNull);
      expect(parse('https://tenk.microscotch.net.evil.example/j/ABCDE'), isNull);
    });

    test('refuse un schéma qui n\'est pas https', () {
      expect(parse('http://tenk.microscotch.net/j/ABCDE'), isNull);
      expect(parse('tenk://join/ABCDE'), isNull);
    });

    test('refuse un autre chemin', () {
      expect(parse('https://tenk.microscotch.net/'), isNull);
      expect(parse('https://tenk.microscotch.net/ws'), isNull);
      expect(parse('https://tenk.microscotch.net/x/ABCDE'), isNull);
      expect(parse('https://tenk.microscotch.net/j/ABCDE/plus'), isNull);
      expect(parse('https://tenk.microscotch.net/j'), isNull);
    });

    test('refuse un code mal formé', () {
      expect(parse('https://tenk.microscotch.net/j/ABCD'), isNull, reason: 'trop court');
      expect(parse('https://tenk.microscotch.net/j/ABCDEF'), isNull, reason: 'trop long');
      expect(parse('https://tenk.microscotch.net/j/AB0DE'), isNull, reason: '0 hors alphabet');
      expect(parse('https://tenk.microscotch.net/j/ABIDE'), isNull, reason: 'I hors alphabet');
    });
  });
}
