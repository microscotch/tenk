import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/dice_off_providers.dart';
import '../state/game_save_store.dart';
import 'screens/dice_off_screen.dart';
import 'screens/setup_screen.dart';

/// Lance le rejeu spectateur de [game], départage compris : le même chemin,
/// que le rejeu soit demandé depuis l'écran de fin de partie ou depuis une
/// partie archivée (voir `DiceOffNotifier.startReplay`).
void openReplay(BuildContext context, WidgetRef ref, SavedGame game) {
  ref.read(diceOffProvider.notifier).startReplay(game);
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const DiceOffScreen(replayMode: true)),
  );
}

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
