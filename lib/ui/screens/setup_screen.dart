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
import '../widgets/menu_die.dart';
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

  /// Non nul pendant la visite de l'accueil du tutoriel : une clé par jeton,
  /// dans l'ordre du rack, pour que ses bulles les montrent. L'écran n'y fait
  /// alors rien de lui-même (ni reprise proposée, ni lien d'invitation ouvert).
  final List<GlobalKey>? tourKeys;

  /// Le nombre de jetons du rack (voir [tourKeys]).
  static const chipCount = 9;

  const SetupScreen({super.key, this.tourKeys});

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
      if (widget.tourKeys != null) return;
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
      if (code != null && widget.tourKeys == null) _openPendingRoomCode();
    });
    // Pas de barre du haut : son titre a sa propre zone en haut de l'écran, et
    // tout ce qu'elle portait d'autre (règles, paramètres, à propos) est devenu
    // un bouton, sous les autres.
    return Scaffold(
      // Des dés, et rien d'autre : un rack de 3×3 dés vus de trois quarts, une
      // icône sur chaque face et leur nom dessous (voir [MenuDie]). Le titre en
      // haut, le rack centré dans le reste de la hauteur (défilant si l'écran
      // est trop bas).
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
                  padding: const EdgeInsets.all(_rackPadding),
                  child: _ChipRack(
                    keys: widget.tourKeys,
                    chips: [
                      _MenuChip(_newGameLook, l10n.newGameSectionLabel, _openNewGame),
                      _MenuChip(_onlineLook, l10n.onlinePlayButton, () => _open(const OnlineEntryScreen())),
                      // Inerte tant qu'il n'y a rien à reprendre : ouvrir un écran
                      // sur une liste vide n'apprendrait rien au joueur.
                      _MenuChip(
                        _resumeLook,
                        l10n.resumeGamesButton,
                        pausedCount == 0 ? null : () => _open(const PausedGamesScreen()),
                      ),
                      _MenuChip(_playersLook, l10n.managePlayersButton, () => _open(const PlayersScreen())),
                      _MenuChip(_finishedLook, l10n.finishedGamesButton, () => _open(const FinishedGamesScreen())),
                      _MenuChip(_statisticsLook, l10n.statisticsButton, () => _open(const StatisticsScreen())),
                      _MenuChip(_helpLook, l10n.helpTooltip, () => _open(const RulesScreen(canReplayTutorial: true))),
                      _MenuChip(_settingsLook, l10n.settingsTooltip, () => _open(const SettingsScreen())),
                      _MenuChip(_aboutLook, l10n.aboutTooltip, () => showAppAboutDialog(context)),
                    ],
                  ),
                ),
              ),
            ),
            // Une mise à jour arrivée sur le store, s'il y en a une.
            const UpdateBanner(),
          ],
        ),
      ),
    );
  }
}

/// La marge autour du rack, de chaque côté.
const double _rackPadding = 16;

/// Un jeton du menu : son icône, son nom, ses couleurs, son action (nulle :
/// inerte).
class _MenuChip {
  final _ChipLook look;
  final String label;
  final VoidCallback? onPressed;

  const _MenuChip(this.look, this.label, this.onPressed);

  IconData get icon => look.icon;
  _ChipColors get colors => look.colors;
}

typedef _ChipColors = ({Color color, Color ink});

/// Ce qui se peint sur un dé du menu (son icône et ses couleurs), par opposition
/// à son nom et à son action : c'est tout ce dont [precacheMenuDice] a besoin.
typedef _ChipLook = ({IconData icon, _ChipColors colors});

const _ChipLook _newGameLook = (icon: Icons.add, colors: _chipGold);
const _ChipLook _onlineLook = (icon: Icons.public, colors: _chipBlue);
const _ChipLook _resumeLook = (icon: Icons.play_arrow, colors: _chipGreen);
const _ChipLook _playersLook = (icon: Icons.group, colors: _chipRed);
const _ChipLook _finishedLook = (icon: Icons.history, colors: _chipPurple);
const _ChipLook _statisticsLook = (icon: Icons.bar_chart, colors: _chipBlack);
const _ChipLook _helpLook = (icon: Icons.help_outline, colors: _chipWhite);
const _ChipLook _settingsLook = (icon: Icons.settings, colors: _chipGrey);
const _ChipLook _aboutLook = (icon: Icons.info_outline, colors: _chipOrange);

/// Les neuf dés du menu, dans l'ordre du rack.
const List<_ChipLook> _menuLooks = [
  _newGameLook,
  _onlineLook,
  _resumeLook,
  _playersLook,
  _finishedLook,
  _statisticsLook,
  _helpLook,
  _settingsLook,
  _aboutLook,
];

/// Calcule d'avance l'image des neuf dés du menu (voir [MenuDie.precache]), l'un
/// après l'autre pour ne pas bloquer l'écran en cours : le splash l'appelle pour
/// que l'accueil les trouve prêts. La taille est celle que le rack leur donnera
/// (voir [_ChipRack.dieSizeFor]) ; une erreur de rendu est sans conséquence,
/// l'accueil recalcule alors ce qui manque.
Future<void> precacheMenuDice(BuildContext context) async {
  final media = MediaQuery.of(context);
  final size = _ChipRack.dieSizeFor(media.size.width - media.padding.horizontal - 2 * _rackPadding);
  for (final look in _menuLooks) {
    try {
      await MenuDie.precache(
        icon: look.icon,
        color: look.colors.color,
        ink: look.colors.ink,
        size: size,
        pixelRatio: media.devicePixelRatio,
      );
    } catch (_) {}
  }
}

// Une couleur de jeton de casino par entrée du menu.
const _ChipColors _chipGold = (color: Color(0xFFC9A227), ink: Color(0xFF3A2A08));
const _ChipColors _chipBlue = (color: Color(0xFF1F5FA8), ink: Colors.white);
const _ChipColors _chipGreen = (color: Color(0xFF2E7D4F), ink: Colors.white);
const _ChipColors _chipRed = (color: Color(0xFFB3261E), ink: Colors.white);
const _ChipColors _chipPurple = (color: Color(0xFF5E35B1), ink: Colors.white);
const _ChipColors _chipBlack = (color: Color(0xFF1B1B1B), ink: Color(0xFFE8D9B0));
const _ChipColors _chipWhite = (color: Color(0xFFEDE6D6), ink: Color(0xFF3A2A08));
const _ChipColors _chipGrey = (color: Color(0xFF6B6F73), ink: Colors.white);
const _ChipColors _chipOrange = (color: Color(0xFFD9732B), ink: Colors.white);

/// Le rack : les jetons du menu en grille de trois colonnes, quelle que soit la
/// largeur de l'écran. Ils mesurent 96
/// au plus, moins sur un écran étroit, pour que les trois colonnes tiennent.
class _ChipRack extends StatelessWidget {
  final List<_MenuChip> chips;

  /// Une clé par jeton, dans l'ordre (voir [SetupScreen.tourKeys]).
  final List<GlobalKey>? keys;

  const _ChipRack({required this.chips, this.keys});

  static const _maxSize = 96.0;
  static const _gap = 12.0;

  /// Le côté d'un dé dans un rack de [rackWidth] de large.
  static double dieSizeFor(double rackWidth) =>
      math.min(_maxSize, (rackWidth - 2 * _gap) / 3 - MenuDie.captionMargin);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = dieSizeFor(constraints.maxWidth);
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
                  for (final (i, chip) in chips.indexed.skip(row).take(3))
                    MenuDie(
                      key: keys?[i],
                      icon: chip.icon,
                      label: chip.label,
                      color: chip.colors.color,
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
