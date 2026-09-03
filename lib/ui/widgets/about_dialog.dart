import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/generated/app_localizations.dart';

/// Mention d'auteur affichée à l'identique sur l'écran d'introduction
/// ([SplashScreen]) et dans le dialogue "À propos" ([showAppAboutDialog]) :
/// un seul endroit à modifier si elle change un jour.
const kAppTagline = 'a fully vibe-coded app from a raspberry pi 5 with claude-code';

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

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
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
          const SizedBox(height: 10),
          Text(
            l10n.splashPresents,
            style: textTheme.titleMedium?.copyWith(letterSpacing: 1.2),
          ),
          const SizedBox(height: 6),
          ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              colors: [colorScheme.primary.withValues(alpha: 0.4), colorScheme.primary],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(rect),
            child: Text(
              '10K',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
          ),
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
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.closeButton),
        ),
      ],
    ),
  );
}
