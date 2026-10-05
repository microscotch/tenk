import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/update_check.dart';

/// Le bandeau de l'accueil qui annonce une mise à jour (voir
/// [availableUpdateProvider]) : « Mettre à jour » ouvre Google Play ou
/// TestFlight, « Plus tard » le fait disparaître jusqu'au build suivant.
///
/// Un bandeau dans la page plutôt qu'une fenêtre : la vérification passe par le
/// réseau et peut répondre après la proposition de reprise ou l'ouverture d'un
/// lien d'invitation, qu'une fenêtre viendrait recouvrir. Rien du tout tant
/// qu'il n'y a rien à proposer.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(availableUpdateProvider).value;
    final platform = ref.watch(updateCheckEnvironmentProvider).platform;
    if (update == null || platform == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.system_update),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.updateAvailableMessage(update.version, update.build))),
              ],
            ),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => ref.read(availableUpdateProvider.notifier).dismiss(),
                  child: Text(l10n.updateLaterButton),
                ),
                TextButton(
                  onPressed: () => launchUrl(storeUrlFor(platform), mode: LaunchMode.externalApplication),
                  child: Text(l10n.updateNowButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
