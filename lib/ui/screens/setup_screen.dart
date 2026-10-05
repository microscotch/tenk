import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_save_store.dart';
import '../../state/room_link_providers.dart';
import '../navigation.dart';
import '../route_observer.dart';
import '../widgets/about_dialog.dart';
import '../widgets/app_title.dart';
import '../widgets/casino_chip.dart';
import '../widgets/update_banner.dart';
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
      // Des jetons, et rien d'autre : un « rack » de 3×3 jetons de casino, une
      // icône chacun, leur nom à l'appui long (voir [CasinoChip]). Le titre en
      // haut, le rack centré dans le reste de la hauteur (défilant si l'écran
      // est trop bas), et une ligne qui dit comment lire les jetons.
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
                  child: _ChipRack(
                    chips: [
                      _MenuChip(Icons.add, l10n.newGameSectionLabel, _chipGold, _openNewGame),
                      _MenuChip(Icons.public, l10n.onlinePlayButton, _chipBlue, () => _open(const OnlineEntryScreen())),
                      // Inerte tant qu'il n'y a rien à reprendre : ouvrir un écran
                      // sur une liste vide n'apprendrait rien au joueur.
                      _MenuChip(
                        Icons.play_arrow,
                        l10n.resumeGamesButton,
                        _chipGreen,
                        pausedCount == 0 ? null : () => _open(const PausedGamesScreen()),
                      ),
                      _MenuChip(Icons.group, l10n.managePlayersButton, _chipRed, () => _open(const PlayersScreen())),
                      _MenuChip(Icons.history, l10n.finishedGamesButton, _chipPurple, () => _open(const FinishedGamesScreen())),
                      _MenuChip(Icons.bar_chart, l10n.statisticsButton, _chipBlack, () => _open(const StatisticsScreen())),
                      _MenuChip(Icons.help_outline, l10n.helpTooltip, _chipWhite, () => _open(const RulesScreen())),
                      _MenuChip(Icons.settings, l10n.settingsTooltip, _chipGrey, () => _open(const SettingsScreen())),
                      _MenuChip(Icons.info_outline, l10n.aboutTooltip, _chipOrange, () => showAppAboutDialog(context)),
                    ],
                  ),
                ),
              ),
            ),
            // Une mise à jour arrivée sur le store, s'il y en a une.
            const UpdateBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                l10n.homeChipsHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Un jeton du menu : son icône, son nom, ses couleurs, son action (nulle :
/// inerte).
class _MenuChip {
  final IconData icon;
  final String label;
  final _ChipColors colors;
  final VoidCallback? onPressed;

  const _MenuChip(this.icon, this.label, this.colors, this.onPressed);
}

typedef _ChipColors = ({Color color, Color edge, Color ink});

// Une couleur de jeton de casino par entrée du menu.
const _ChipColors _chipGold = (color: Color(0xFFC9A227), edge: Color(0xFFFFF3C4), ink: Color(0xFF3A2A08));
const _ChipColors _chipBlue = (color: Color(0xFF1F5FA8), edge: Color(0xFFEAF2FF), ink: Colors.white);
const _ChipColors _chipGreen = (color: Color(0xFF2E7D4F), edge: Color(0xFFE9F7EE), ink: Colors.white);
const _ChipColors _chipRed = (color: Color(0xFFB3261E), edge: Color(0xFFFFE9E6), ink: Colors.white);
const _ChipColors _chipPurple = (color: Color(0xFF5E35B1), edge: Color(0xFFF1EAFF), ink: Colors.white);
const _ChipColors _chipBlack = (color: Color(0xFF1B1B1B), edge: Color(0xFFE8D9B0), ink: Color(0xFFE8D9B0));
const _ChipColors _chipWhite = (color: Color(0xFFEDE6D6), edge: Color(0xFFB3261E), ink: Color(0xFF3A2A08));
const _ChipColors _chipGrey = (color: Color(0xFF6B6F73), edge: Color(0xFFF2F2F2), ink: Colors.white);
const _ChipColors _chipOrange = (color: Color(0xFFD9732B), edge: Color(0xFFFFF0E2), ink: Colors.white);

/// Le rack : les jetons du menu en grille de trois colonnes, quelle que soit la
/// largeur de l'écran. Ils mesurent 96
/// au plus, moins sur un écran étroit, pour que les trois colonnes tiennent.
class _ChipRack extends StatelessWidget {
  final List<_MenuChip> chips;

  const _ChipRack({required this.chips});

  static const _maxSize = 96.0;
  static const _gap = 26.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(_maxSize, (constraints.maxWidth - 2 * _gap) / 3);
        // Toujours trois colonnes, même sur un écran large : c'est un rack, pas
        // une rangée qui s'étire.
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: _gap,
          children: [
            for (var row = 0; row < chips.length; row += 3)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: _gap,
                children: [
                  for (final chip in chips.skip(row).take(3))
                    CasinoChip(
                      icon: chip.icon,
                      label: chip.label,
                      color: chip.colors.color,
                      edge: chip.colors.edge,
                      ink: chip.colors.ink,
                      size: size,
                      onPressed: chip.onPressed,
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
