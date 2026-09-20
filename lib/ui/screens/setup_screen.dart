import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/game_save_store.dart';
import '../route_observer.dart';
import '../widgets/about_dialog.dart';
import '../widgets/app_title.dart';
import 'finished_games_screen.dart';
import 'game_screen.dart';
import 'new_game_screen.dart';
import 'paused_games_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';

/// Écran d'accueil : cinq boutons, et rien d'autre.
///
/// Les parties interrompues et les parties terminées s'affichaient ici en
/// permanence, chacune dans sa zone bordurée ; l'écran en était chargé au point
/// de noyer le seul geste courant, démarrer une partie. Chaque liste vit
/// désormais derrière son bouton, dans un écran dédié qui la réutilise telle
/// quelle ([PausedGamesScreen], [FinishedGamesScreen]).
class SetupScreen extends ConsumerStatefulWidget {
  /// Nom de route de l'écran d'accueil, posé par [SplashScreen] au moment de
  /// le pousser. Revenir ici depuis n'importe quelle profondeur se fait par
  /// `popUntil` sur ce nom (voir [GameOverScreen], `game_screen.dart`) plutôt
  /// qu'en se fiant à `route.isFirst` : le nom désigne explicitement CET
  /// écran, là où `isFirst` désigne juste « le bas de la pile », quel qu'il
  /// soit.
  static const routeName = '/home';

  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    // postFrameCallback : la popup a besoin d'un BuildContext déjà inséré
    // dans l'arbre (Navigator, thème...) pour showDialog. Cet écran n'étant
    // jamais re-poussé (voir didPopNext ci-dessous), initState ne se
    // déclenche qu'une fois par session — pas de popup répétée à chaque
    // retour au menu principal après une partie.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeOfferResume());
  }

  Future<void> _maybeOfferResume() async {
    if (!mounted) return;
    final games = await ref.read(pausedGamesProvider.future);
    if (!mounted || games.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final mostRecent = games.first; // trié par date de modif décroissante
    final resume = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.resumeLastGameDialogTitle),
        content: Text(l10n.resumeLastGameDialogMessage(mostRecent.alias)),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancelButton)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.resumeGameButton)),
        ],
      ),
    );
    if (resume == true && mounted) {
      ref.read(gameProvider.notifier).resumeFromSave(mostRecent);
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameScreen()));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) routeObserver.subscribe(this, route);
  }

  /// Cet écran n'est jamais re-poussé (il reste toujours la toute première
  /// route de la pile, voir `game_over_screen.dart`) : `didPopNext` (une
  /// route poussée par-dessus vient d'être dépilée) est le bon moment pour
  /// rafraîchir les listes de parties en pause et de runs terminés — leurs
  /// libellés (avec compteur) et leur contenu suivent automatiquement.
  @override
  void didPopNext() {
    ref.invalidate(pausedGamesProvider);
    ref.invalidate(finishedGamesProvider);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  void _openNewGame() => _open(const NewGameScreen());

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Seul le compte des parties en pause sert encore ici : il décide si le
    // bouton de reprise est actif. Les deux écrans dédiés titrent avec le leur.
    final pausedCount = ref.watch(pausedGamesProvider).value?.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: const AppTitle(),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.aboutTooltip,
            onPressed: () => showAppAboutDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.helpTooltip,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RulesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.settingsTooltip,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      // Cinq boutons, et rien d'autre : les deux listes qui s'affichaient ici en
      // permanence vivent désormais derrière le leur (voir [PausedGamesScreen]
      // et [FinishedGamesScreen]), qui les réutilisent telles quelles.
      //
      // Les boutons des fonctions pas encore écrites sont rendus quand même,
      // inertes : la disposition de l'écran est ainsi figée dès maintenant, et
      // les activer ne coûtera qu'une ligne.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  onPressed: _openNewGame,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.newGameSectionLabel),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  // Inerte tant qu'il n'y a rien à reprendre : ouvrir un écran
                  // sur une liste vide n'apprendrait rien au joueur.
                  onPressed: pausedCount == 0 ? null : () => _open(const PausedGamesScreen()),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.resumeGamesButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.group),
                  label: Text(l10n.managePlayersButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _open(const FinishedGamesScreen()),
                  icon: const Icon(Icons.history),
                  label: Text(l10n.finishedGamesButton),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.bar_chart),
                  label: Text(l10n.statisticsButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
