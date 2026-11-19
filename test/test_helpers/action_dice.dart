import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/menu_die.dart';

/// Les dés de la barre d'action de l'écran de jeu (voir `ActionDie`), par rôle.
Finder actionDie(ActionDieKind kind) =>
    find.byWidgetPredicate((w) => w is ActionDie && w.kind == kind, description: 'dé $kind');

/// Le dé « Lancer ».
Finder get rollDie => actionDie(ActionDieKind.roll);

/// Le dé Stop.
Finder get stopDie => actionDie(ActionDieKind.stop);

/// Le dé de recyclage (le choix des 5).
Finder get exchangeDie => actionDie(ActionDieKind.exchange);

/// Le dé gris du tour d'un autre joueur.
Finder get observedDie => actionDie(ActionDieKind.observed);

/// Le dé de [finder], pour lire son `onPressed`.
ActionDie dieOf(WidgetTester tester, Finder finder) => tester.widget<ActionDie>(finder);

/// Le dé dont le libellé est [caption] — tel que le lecteur d'écran l'annonce :
/// sous le dé gris d'un autre joueur, le nom s'affiche en pastille.
Finder dieWithCaption(String caption) =>
    find.byWidgetPredicate((w) => w is ActionDie && w.caption == caption, description: 'dé « $caption »');
