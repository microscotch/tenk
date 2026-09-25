import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_save_store.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/finished_games_list.dart';

/// Les parties terminées, rejouables en spectateur — sorties de l'écran
/// d'accueil pour le désencombrer. Même principe que [PausedGamesScreen] :
/// [FinishedGamesList] est réutilisé sans modification.
class FinishedGamesScreen extends ConsumerWidget {
  const FinishedGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(finishedGamesProvider).value?.length ?? 0;
    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.finishedRunsSectionLabel(count))),
      body: const SafeArea(
        child: Padding(padding: EdgeInsets.all(16), child: FinishedGamesList()),
      ),
    );
  }
}
