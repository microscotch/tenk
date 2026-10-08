import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/tutorial.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/settings_providers.dart';
import '../widgets/tutorial_overlay.dart';
import 'game_screen.dart';

/// Le tutoriel : une vraie partie sur le vrai écran de jeu ([GameScreen] en
/// mode tutoriel), contre un bot qui ne jouera pas, sur des dés scénarisés
/// ([tutorialFaces]). Des bulles montrent la commande à toucher (voir
/// [TutorialOverlay]) ; l'étape suivante vient de l'état de la partie.
///
/// Ce n'est pas une partie pour autant : ni seed, ni sauvegarde, ni
/// statistiques (voir [GameNotifier.startTutorial]). Il remplace l'état du
/// notifier de partie, qui est celui de l'écran de jeu : ne l'ouvrir que depuis
/// un écran sans partie empilée dessous (le premier lancement, l'accueil).
///
/// Proposé au tout premier lancement (voir `launchScreenFor`), avec la page
/// [next] à ouvrir ensuite ; sans [next] (rejoué depuis l'écran des règles), il
/// se referme simplement. Se passe à tout moment, retour système compris ; fini
/// ou passé, il compte comme vu.
class TutorialScreen extends ConsumerStatefulWidget {
  final Widget? next;

  const TutorialScreen({super.key, this.next});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  late final TutorialGuide _guide = TutorialGuide(onExit: _leave);
  bool _started = false;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    // Après la première construction : un provider ne se modifie pas pendant
    // celle-ci. Les noms viennent de la langue de l'écran, d'où `context`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ref
          .read(gameProvider.notifier)
          .startTutorial(playerName: l10n.tutorialPlayerName, botName: l10n.botLabel, faces: tutorialFaces);
      setState(() => _started = true);
    });
  }

  /// Sort du tutoriel, fini ou passé : il compte comme vu dans les deux cas, et
  /// la partie qu'il jouait ne reste pas à l'écran.
  void _leave() {
    if (_left || !mounted) return;
    _left = true;
    ref.read(settingsProvider.notifier).markTutorialSeen();
    ref.read(gameProvider.notifier).endTutorial();
    final next = widget.next;
    if (next == null) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => next));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return GameScreen(tutorial: _guide);
  }
}
