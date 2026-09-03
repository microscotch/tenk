import 'package:flutter/widgets.dart';

import 'screens/setup_screen.dart';

/// Dépile jusqu'à l'écran d'accueil, depuis n'importe quelle profondeur
/// (fin de partie, abandon en cours de partie...).
///
/// Le prédicat teste d'abord le nom de route ([SetupScreen.routeName], posé
/// par l'écran d'introduction) : il désigne explicitement l'accueil, alors que
/// `route.isFirst` ne désigne que « le bas de la pile », quel qu'il soit.
/// `isFirst` reste dans le prédicat comme garde-fou : sans lui, une pile où le
/// nom serait absent (route poussée autrement, écran d'accueil atteint par un
/// chemin futur) se viderait entièrement — c'est exactement ce qui laisse un
/// écran vide à l'utilisateur.
///
/// Revient toujours sur l'INSTANCE existante de [SetupScreen] plutôt que d'en
/// pousser une nouvelle : celle-ci ne propose sa reprise de partie qu'à sa
/// création (voir `SetupScreen.initState`), une nouvelle instance rejouerait
/// donc cette popup après chaque partie.
void popToHome(BuildContext context) {
  Navigator.of(context).popUntil(
    (route) => route.isFirst || route.settings.name == SetupScreen.routeName,
  );
}
