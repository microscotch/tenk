/// La lettre d'un joueur pour sa pastille : la première lettre de son nom
/// affiché (le surnom quand il en a un, voir `PlayerProfile.displayName`), en
/// majuscule. Nom vide (ou uniquement des espaces) : "?".
///
/// Par point de code, pas par unité UTF-16 : un emoji en tête de nom se coupait
/// en deux moitiés de paire de substitution, et le texte de la pastille refusait
/// de s'afficher (« string is not well-formed UTF-16 »). Et on garde ce qui se lit
/// avec le caractère : sa teinte de peau, son sélecteur d'emoji, ses accents
/// combinants, et les deux moitiés d'un drapeau — sans quoi la pastille montrerait
/// un carré de couleur, ou la moitié d'un drapeau.
String avatarLetterFor(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final r = trimmed.runes.toList();
  var end = 1;
  if (_isRegionalIndicator(r[0]) && r.length > 1 && _isRegionalIndicator(r[1])) end = 2;
  while (end < r.length && _isAttached(r[end])) {
    end++;
  }
  final initial = String.fromCharCodes(r.sublist(0, end));
  final up = initial.toUpperCase();
  // « ß » devient « SS » : une initiale reste une seule lettre.
  return up.runes.length == initial.runes.length ? up : initial;
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
