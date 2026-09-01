import 'dart:math';

/// Adjectifs (accordés au masculin, comme tous les noms de [_kAliasNouns])
/// utilisés pour composer l'alias d'une partie.
const List<String> _kAliasAdjectives = [
  'Chanceux',
  'Espiègle',
  'Audacieux',
  'Rusé',
  'Increvable',
  'Doré',
  'Fébrile',
  'Roublard',
  'Intrépide',
  'Cabotin',
  'Flamboyant',
  'Malicieux',
  'Téméraire',
  'Facétieux',
  'Endiablé',
];

/// Noms (thème table de jeu / dés), tous masculins pour rester accordés avec
/// [_kAliasAdjectives] sans avoir à gérer le genre.
const List<String> _kAliasNouns = [
  'Dé',
  'Brelan',
  'Croupier',
  'Jackpot',
  'Trictrac',
  'Loustic',
  'Farkle',
  'Domino',
  'Tapis',
  'Feutre',
  'Cornet',
  'Gobelet',
  'As',
  'Quinté',
  'Sabot',
];

/// Alias aléatoire pour une nouvelle partie (ex: "Facétieux Croupier"),
/// tiré localement sans dépendance réseau. Choisi une seule fois à la
/// création de la partie puis persisté : n'a pas besoin d'être rejouable.
String randomGameAlias([Random? random]) {
  final rng = random ?? Random();
  final adjective = _kAliasAdjectives[rng.nextInt(_kAliasAdjectives.length)];
  final noun = _kAliasNouns[rng.nextInt(_kAliasNouns.length)];
  return '$adjective $noun';
}
