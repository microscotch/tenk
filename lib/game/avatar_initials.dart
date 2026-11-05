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

  // Par point de code, pas par unité UTF-16 : un emoji en tête ou en queue de nom
  // se coupait en deux moitiés de paire de substitution, et le texte du blason
  // refusait de s'afficher (« string is not well-formed UTF-16 »).
  String first(String word) => String.fromCharCode(word.runes.first);
  String last(String word) => String.fromCharCode(word.runes.last);

  if (words.length == 1) {
    final word = words.first;
    return (first(word) + last(word)).toUpperCase();
  }

  return (first(words[0]) + first(words[1])).toUpperCase();
}
