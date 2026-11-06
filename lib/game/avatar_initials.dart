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
  // refusait de s'afficher (« string is not well-formed UTF-16 »). Et on garde ce qui
  // se lit avec le caractère : sa teinte de peau, son sélecteur d'emoji, ses accents
  // combinants, et les deux moitiés d'un drapeau — sans quoi le blason montrerait un
  // carré de couleur, ou la moitié d'un drapeau.
  String upper(String initial) {
    final up = initial.toUpperCase();
    // « ß » devient « SS » : une initiale reste une seule lettre.
    return up.runes.length == initial.runes.length ? up : initial;
  }

  String first(String word) {
    final r = word.runes.toList();
    var end = 1;
    if (_isRegionalIndicator(r[0]) && r.length > 1 && _isRegionalIndicator(r[1])) end = 2;
    while (end < r.length && _isAttached(r[end])) {
      end++;
    }
    return upper(String.fromCharCodes(r.sublist(0, end)));
  }

  String last(String word) {
    final r = word.runes.toList();
    var start = r.length - 1;
    while (start > 0 && _isAttached(r[start])) {
      start--;
    }
    if (_isRegionalIndicator(r[start]) && start > 0 && _isRegionalIndicator(r[start - 1])) start--;
    return upper(String.fromCharCodes(r.sublist(start)));
  }

  if (words.length == 1) {
    final word = words.first;
    return first(word) + last(word);
  }

  return first(words[0]) + first(words[1]);
}

bool _isRegionalIndicator(int r) => r >= 0x1F1E6 && r <= 0x1F1FF;

/// Ce qui s'attache au caractère qui précède et ne se lit pas seul : accents
/// combinants, sélecteurs de variation, teintes de peau, étiquettes de drapeaux.
bool _isAttached(int r) =>
    (r >= 0x300 && r <= 0x36F) ||
    r == 0xFE0E ||
    r == 0xFE0F ||
    (r >= 0x1F3FB && r <= 0x1F3FF) ||
    (r >= 0xE0020 && r <= 0xE007F);
