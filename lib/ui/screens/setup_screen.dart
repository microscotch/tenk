import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_save_store.dart';
import '../../state/room_link_providers.dart';
import '../navigation.dart';
import '../route_observer.dart';
import '../widgets/about_dialog.dart';
import '../widgets/app_title.dart';
import 'finished_games_screen.dart';
import 'new_game_screen.dart';
import 'online_entry_screen.dart';
import 'paused_games_screen.dart';
import 'players_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'statistics_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Un lien d'invitation qui a lancé l'application passe avant la reprise.
      if (_openPendingRoomCode()) return;
      _maybeOfferResume();
    });
  }

  /// Ouvre l'entrée en ligne sur le code qu'un lien d'invitation vient de
  /// proposer. Attend que l'accueil soit l'écran affiché : un lien reçu en pleine
  /// partie ne doit pas la recouvrir, il s'ouvre au retour ([didPopNext]).
  bool _openPendingRoomCode() {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return false;
    final code = ref.read(pendingRoomCodeProvider.notifier).take();
    if (code == null) return false;
    _open(OnlineEntryScreen(initialCode: code));
    return true;
  }

  Future<void> _maybeOfferResume() async {
    if (!mounted) return;
    final games = await ref.read(pausedGamesProvider.future);
    if (!mounted || games.isEmpty) return;
    // Un lien arrivé pendant le chargement de la liste passe avant la reprise.
    if (_openPendingRoomCode()) return;
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
      resumeSavedGame(context, ref, mostRecent);
    } else {
      // Un lien reçu pendant que la fenêtre était ouverte attendait sa fermeture.
      _openPendingRoomCode();
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
    // Après la frame : pousser une route pendant que le navigateur met sa pile à
    // jour (c'est le cas ici) est interdit.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPendingRoomCode());
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
    // Un lien qui arrive pendant que l'accueil est affiché (application déjà
    // ouverte). Ailleurs ou sous une fenêtre, il reste en attente.
    ref.listen(pendingRoomCodeProvider, (_, code) {
      if (code != null) _openPendingRoomCode();
    });
    // Pas de barre du haut : son titre a sa propre zone en haut de l'écran, et
    // tout ce qu'elle portait d'autre (règles, paramètres, à propos) est devenu
    // un bouton, sous les autres.
    return Scaffold(
      // Des boutons, et rien d'autre : les deux listes qui s'affichaient ici en
      // permanence vivent désormais derrière le leur (voir [PausedGamesScreen]
      // et [FinishedGamesScreen]), qui les réutilisent telles quelles.
      // Deux zones : le titre, calé en haut de l'écran, puis tout le reste de
      // la hauteur pour les boutons, centrés dans cette zone (et défilants si
      // l'écran est trop bas pour les contenir tous).
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Center(child: AppTitle(large: true)),
            ),
            Expanded(
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
                      FilledButton.tonalIcon(
                        onPressed: () => _open(const OnlineEntryScreen()),
                        icon: const Icon(Icons.public),
                        label: Text(l10n.onlinePlayButton),
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
                        onPressed: () => _open(const PlayersScreen()),
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
                        onPressed: () => _open(const StatisticsScreen()),
                        icon: const Icon(Icons.bar_chart),
                        label: Text(l10n.statisticsButton),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _open(const RulesScreen()),
                        icon: const Icon(Icons.help_outline),
                        label: Text(l10n.helpTooltip),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => _open(const SettingsScreen()),
                        icon: const Icon(Icons.settings),
                        label: Text(l10n.settingsTooltip),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => showAppAboutDialog(context),
                        icon: const Icon(Icons.info_outline),
                        label: Text(l10n.aboutTooltip),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
