import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/dice_off_providers.dart';
import '../state/game_providers.dart';
import '../state/game_save_store.dart';
import '../state/replay_pause_provider.dart';
import 'screens/dice_off_screen.dart';
import 'screens/game_screen.dart';
import 'screens/setup_screen.dart';

/// Reprend une partie en pause, depuis la liste des parties en pause comme
/// depuis la proposition de l'accueil : sur son départage s'il n'était pas
/// tranché (la partie n'existe pas encore), sinon sur la partie elle-même.
void resumeSavedGame(BuildContext context, WidgetRef ref, SavedGame saved) {
  if (DiceOffNotifier.isUnfinished(saved)) {
    ref.read(diceOffProvider.notifier).resumeFromSave(saved);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiceOffScreen()));
    return;
  }
  ref.read(gameProvider.notifier).resumeFromSave(saved);
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameScreen()));
}

/// Lance le rejeu spectateur de [game], droit sur sa partie : le tirage au sort
/// qui a fixé l'ordre de jeu n'est pas remis en scène (voir
/// `GameNotifier.startReplay`). Le même chemin, que le rejeu soit demandé depuis
/// l'écran de fin de partie ou depuis une partie archivée.
///
/// Rend faux, sans rien ouvrir, quand le journal ne permet pas de rejouer (un
/// run illisible, dont le départage n'a pas de vainqueur) : à l'appelant de le
/// dire à l'utilisateur.
bool openReplay(BuildContext context, WidgetRef ref, SavedGame game) {
  // Un rejeu démarre toujours en lecture, même si le précédent a été quitté
  // en pause.
  ref.read(replayPausedProvider.notifier).set(false);
  try {
    ref.read(gameProvider.notifier).startReplay(game);
  } catch (_) {
    return false;
  }
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const GameScreen(replayMode: true)),
  );
  return true;
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
