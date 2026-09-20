import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/game_save_store.dart';
import '../widgets/paused_games_list.dart';

/// Les parties interrompues, sorties de l'écran d'accueil pour le désencombrer.
///
/// Simple hôte : [PausedGamesList] lit lui-même ses providers et porte déjà la
/// reprise, la suppression par glissement et son message de liste vide — il est
/// repris tel quel. Le titre de la barre remplace le liseré de la zone bordurée
/// qui l'encadrait sur l'accueil, et le `Scaffold` lui apporte la même hauteur
/// bornée, dont sa liste a besoin.
class PausedGamesScreen extends ConsumerWidget {
  const PausedGamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(pausedGamesProvider).value?.length ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pausedGamesSectionLabel(count))),
      body: const SafeArea(
        child: Padding(padding: EdgeInsets.all(16), child: PausedGamesList()),
      ),
    );
  }
}
