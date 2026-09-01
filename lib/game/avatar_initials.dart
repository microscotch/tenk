/// Calcule les 2 initiales d'un joueur pour son avatar (blason), à partir
/// des "éléments nominaux" de son nom (les mots séparés par des espaces).
///
/// - 2 éléments ou plus : la première lettre des 2 premiers mots.
/// - 1 seul élément (nom en un seul mot) : sa première lettre, puis sa
///   dernière — il n'y a qu'un seul mot dont tirer une initiale, donc la
///   seconde lettre du blason vient de la fin du même mot plutôt que d'un
///   mot inexistant.
/// - Nom vide (ou uniquement des espaces) : "??".
String avatarInitialsFor(String name) {
  final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '??';

  if (words.length == 1) {
    final word = words.first;
    return (word[0] + word[word.length - 1]).toUpperCase();
  }

  return (words[0][0] + words[1][0]).toUpperCase();
}
