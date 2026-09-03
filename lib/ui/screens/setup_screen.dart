import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/game_save_store.dart';
import '../route_observer.dart';
import '../widgets/about_dialog.dart';
import '../widgets/app_title.dart';
import '../widgets/bordered_section.dart';
import '../widgets/finished_games_list.dart';
import '../widgets/paused_games_list.dart';
import 'game_screen.dart';
import 'new_game_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';

/// Écran d'accueil : un bouton pour démarrer une nouvelle partie (ouvre
/// [NewGameScreen]) suivi de 2 zones toujours visibles, réparties également
/// sur le reste de l'écran — les runs interrompus (reprenables) et les
/// runs terminés (rejouables en mode spectateur temporisé).
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

  void _openNewGame() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewGameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pausedCount = ref.watch(pausedGamesProvider).value?.length ?? 0;
    final finishedCount = ref.watch(finishedGamesProvider).value?.length ?? 0;
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _openNewGame,
                icon: const Icon(Icons.add),
                label: Text(l10n.newGameSectionLabel),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BorderedSection(
                  label: l10n.pausedGamesSectionLabel(pausedCount),
                  child: const PausedGamesList(),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: BorderedSection(
                  label: l10n.finishedRunsSectionLabel(finishedCount),
                  child: const FinishedGamesList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
