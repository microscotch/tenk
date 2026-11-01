import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';

/// Le fichier Markdown des crédits : un paragraphe par bibliothèque utilisée par
/// l'application (voir `pubspec.yaml`), plus la police et leurs licences. C'est
/// son contenu, tel quel, que la fenêtre affiche : pour ajouter un crédit, on
/// modifie ce fichier, pas le code.
const kCreditsAsset = 'assets/credits.md';

/// La fenêtre des crédits, ouverte depuis le dialogue « À propos » : le contenu de
/// [kCreditsAsset] rendu en Markdown, dans une fenêtre défilante.
///
/// [bundle] et [openLink] ne servent qu'aux tests (le paquet des ressources de
/// l'application et l'ouverture d'un lien dans le navigateur).
Future<void> showCreditsDialog(
  BuildContext context, {
  AssetBundle? bundle,
  Future<void> Function(String url)? openLink,
}) async {
  final markdown = await (bundle ?? rootBundle).loadString(kCreditsAsset);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.creditsButton),
      content: SizedBox(
        // Toute la largeur disponible du dialogue, sans la dépasser sur un petit écran.
        width: double.maxFinite,
        child: Markdown(
          key: const ValueKey('credits-markdown'),
          data: markdown,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            a: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          onTapLink: (text, href, title) {
            if (href == null) return;
            (openLink ?? _openInBrowser)(href);
          },
        ),
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

Future<void> _openInBrowser(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Pas de navigateur : le lien reste lisible, rien d'autre à faire.
  }
}
