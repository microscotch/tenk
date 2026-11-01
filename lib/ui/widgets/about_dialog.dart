import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/konami_code.dart';
import '../../state/settings_providers.dart';
import '../screens/acknowledgements_screen.dart';
import 'credits_dialog.dart';
import 'die_widget.dart';

/// Mention d'auteur affichée à l'identique sur l'écran d'introduction
/// ([SplashScreen]) et dans le dialogue "À propos" ([showAppAboutDialog]) :
/// un seul endroit à modifier si elle change un jour.
const kAppTagline =
    'a fully vibe-coded app from a raspberry pi 5 with claude-code';

/// Dialogue "À propos" : reprend le contenu de l'écran d'introduction
/// (avatar, "[auteur] présente", "10K", mention d'auteur) en version statique
/// (pas de mise en scène animée, superflue pour un dialogue consulté à la
/// demande), et y ajoute la version de l'application avec son code de
/// version — lus via [PackageInfo] (métadonnées natives embarquées au build,
/// Android `versionCode` / iOS `CFBundleVersion`) plutôt que rejoués depuis
/// `pubspec.yaml`, qui n'existe pas dans le binaire une fois compilé.
Future<void> showAppAboutDialog(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final container = ProviderScope.containerOf(context);
  final konami = KonamiDetector();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      // Les « touches » du code Konami : l'avatar est A, « 10K » est Start, et la
      // croix de dés fait le reste (voir [_AceCross]).
      void press(KonamiKey key) {
        if (!konami.press(key, DateTime.now())) return;
        if (container.read(settingsProvider).advancedMode) return;
        _offerAdvancedMode(dialogContext, container);
      }

      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              key: const ValueKey('konami-a'),
              behavior: HitTestBehavior.opaque,
              onTap: () => press(KonamiKey.a),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.primary, width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/github_avatar.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.splashPresents,
              style: textTheme.titleMedium?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: 6),
            ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.4),
                  colorScheme.primary,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(rect),
              child: GestureDetector(
                key: const ValueKey('konami-start'),
                behavior: HitTestBehavior.opaque,
                onTap: () => press(KonamiKey.start),
                child: Text(
                  '10K',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _AceCross(onKey: press),
            const SizedBox(height: 12),
            Text(
              kAppTagline,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.aboutVersionLabel(info.version, info.buildNumber),
              style: textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Le dialogue se referme : l'écran s'ouvre sur la page qui l'a lancé.
              Navigator.of(dialogContext).pop();
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AcknowledgementsScreen(),
                ),
              );
            },
            child: Text(l10n.acknowledgementsButton),
          ),
          // La fenêtre des crédits s'ouvre par-dessus ce dialogue, qui reste en place.
          TextButton(
            onPressed: () => showCreditsDialog(dialogContext),
            child: Text(l10n.creditsButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.closeButton),
          ),
        ],
      );
    },
  );
}

/// Propose d'entrer en mode avancé une fois le code Konami saisi. Refuser, ou
/// fermer la fenêtre, laisse l'application en mode normal (Wonderland).
Future<void> _offerAdvancedMode(
  BuildContext context,
  ProviderContainer container,
) async {
  final l10n = AppLocalizations.of(context);
  final accepted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.advancedModePromptTitle),
      content: Text(l10n.advancedModePromptBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.advancedModeEnableButton),
        ),
      ],
    ),
  );
  if (accepted == true) {
    container.read(settingsProvider.notifier).setAdvancedMode(true);
  }
}

/// Le clin d'œil sous « 10K » : cinq as posés en croix — un, trois, un —, chaque
/// ligne centrée.
///
/// Elle sert aussi de manette au code Konami (voir `KonamiDetector`) : le dé du
/// haut est ↑ et celui du bas ↓ (les extrémités de la colonne du milieu), ceux de
/// gauche et de droite ← et → (les extrémités de la ligne du milieu), et celui du
/// centre est B.
class _AceCross extends StatelessWidget {
  final ValueChanged<KonamiKey> onKey;

  const _AceCross({required this.onKey});

  static const _keys = [
    [KonamiKey.up],
    [KonamiKey.left, KonamiKey.b, KonamiKey.right],
    [KonamiKey.down],
  ];

  static const _rows = [1, 3, 1];
  static const _dieSize = 52.0;

  @override
  Widget build(BuildContext context) {
    var seed = 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < _rows.length; row++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _rows[row]; i++)
                GestureDetector(
                  key: ValueKey('konami-${_keys[row][i].name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onKey(_keys[row][i]),
                  child: DieWidget(
                    value: 1,
                    state: DieVisualState.kept,
                    size: _dieSize,
                    restSeed: seed++,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
