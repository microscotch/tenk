/// Les touches du code Konami, telles que l'écran « À propos » les simule avec la
/// croix de dés, l'avatar et le texte « 10K ».
enum KonamiKey { up, down, left, right, b, a, start }

/// Le détecteur du code Konami : ↑ ↑ ↓ ↓ ← → ← → B A Start, à saisir en moins de
/// [window] du premier au dernier appui. Pur Dart : le temps lui est donné, ce qui
/// le rend testable sans horloge.
///
/// Il garde les derniers appuis et compare la fin de cette liste au code, plutôt
/// que de repartir de zéro à chaque erreur : se tromper d'une touche juste avant
/// le code ne l'empêche pas de se reconnaître.
class KonamiDetector {
  KonamiDetector({this.window = defaultWindow});

  /// Court mais à la portée de n'importe qui : onze appuis, soit un peu moins
  /// d'une seconde chacun.
  static const defaultWindow = Duration(seconds: 10);

  static const code = [
    KonamiKey.up,
    KonamiKey.up,
    KonamiKey.down,
    KonamiKey.down,
    KonamiKey.left,
    KonamiKey.right,
    KonamiKey.left,
    KonamiKey.right,
    KonamiKey.b,
    KonamiKey.a,
    KonamiKey.start,
  ];

  /// Le temps imparti entre le premier et le dernier appui du code.
  final Duration window;

  final List<(KonamiKey, DateTime)> _presses = [];

  /// Note l'appui de [key] à l'instant [at] ; vrai quand il achève le code (qui
  /// repart alors de zéro).
  bool press(KonamiKey key, DateTime at) {
    _presses.add((key, at));
    if (_presses.length > code.length) _presses.removeAt(0);
    if (_presses.length < code.length) return false;
    for (var i = 0; i < code.length; i++) {
      if (_presses[i].$1 != code[i]) return false;
    }
    final fast = _presses.last.$2.difference(_presses.first.$2) <= window;
    if (fast) _presses.clear();
    return fast;
  }
}
