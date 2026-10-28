import 'package:flutter/material.dart';

import '../state/settings_providers.dart';
import 'page_transitions.dart';

/// Les couleurs de la table qui ne sont pas dans le [ColorScheme] : le feutre
/// du fond et les teintes de sens (gain, perte, alerte, texte discret), qui
/// doivent rester lisibles sur le fond du thème — un vert fluo se lit sur le
/// feutre sombre, pas sur le clair.
@immutable
class TableColors extends ThemeExtension<TableColors> {
  /// Le feutre : le centre éclairé, les bords, le liseré des losanges et
  /// l'opacité de la vignette (le noir des coins).
  final Color feltCenter;
  final Color feltEdge;
  final Color feltLine;
  final double vignette;

  /// Texte et icônes discrets (nom d'un bot, « aucune partie »...).
  final Color muted;

  /// Un gain, ou un coup qui élimine un adversaire.
  final Color positive;

  /// Une perte, un craque, une égalité à éviter.
  final Color negative;

  /// Une alerte : un total qui finit par 50, un tiret.
  final Color warning;

  /// Le texte « neutre » posé sur le feutre, là où une couleur de sens serait
  /// possible (le potentiel d'une main).
  final Color plain;

  /// Le « = 100 » du libellé de la règle d'extension : un jaune vif sur le
  /// feutre sombre, un ocre profond sur le clair.
  final Color extensionLabel;

  const TableColors({
    required this.feltCenter,
    required this.feltEdge,
    required this.feltLine,
    required this.vignette,
    required this.muted,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.plain,
    required this.extensionLabel,
  });

  /// La table d'origine : feutre vert profond, teintes vives.
  static const dark = TableColors(
    feltCenter: Color(0xFF0E3B2C),
    feltEdge: Color(0xFF071F17),
    feltLine: Color(0x14D9A441),
    vignette: 0.45,
    muted: Color(0xFFBDBDBD),
    positive: Colors.lightGreenAccent,
    negative: Colors.redAccent,
    warning: Colors.orange,
    plain: Colors.white,
    extensionLabel: Color(0xFFFFC400),
  );

  /// La variante claire : feutre sauge pâle, liseré or plus soutenu, teintes
  /// foncées pour garder le contraste.
  static const light = TableColors(
    feltCenter: Color(0xFFEAF2E3),
    feltEdge: Color(0xFFC9DABF),
    feltLine: Color(0x33A8791C),
    vignette: 0.10,
    muted: Color(0xFF5A665C),
    positive: Color(0xFF1B7A3D),
    negative: Color(0xFFB3261E),
    warning: Color(0xFFB85C00),
    plain: Color(0xFF1C2A20),
    extensionLabel: Color(0xFF8A5A00),
  );

  static TableColors of(BuildContext context) =>
      Theme.of(context).extension<TableColors>() ?? TableColors.dark;

  @override
  TableColors copyWith({
    Color? feltCenter,
    Color? feltEdge,
    Color? feltLine,
    double? vignette,
    Color? muted,
    Color? positive,
    Color? negative,
    Color? warning,
    Color? plain,
    Color? extensionLabel,
  }) {
    return TableColors(
      feltCenter: feltCenter ?? this.feltCenter,
      feltEdge: feltEdge ?? this.feltEdge,
      feltLine: feltLine ?? this.feltLine,
      vignette: vignette ?? this.vignette,
      muted: muted ?? this.muted,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      warning: warning ?? this.warning,
      plain: plain ?? this.plain,
      extensionLabel: extensionLabel ?? this.extensionLabel,
    );
  }

  @override
  TableColors lerp(TableColors? other, double t) {
    if (other == null) return this;
    return TableColors(
      feltCenter: Color.lerp(feltCenter, other.feltCenter, t)!,
      feltEdge: Color.lerp(feltEdge, other.feltEdge, t)!,
      feltLine: Color.lerp(feltLine, other.feltLine, t)!,
      vignette: vignette + (other.vignette - vignette) * t,
      muted: Color.lerp(muted, other.muted, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      plain: Color.lerp(plain, other.plain, t)!,
      extensionLabel: Color.lerp(extensionLabel, other.extensionLabel, t)!,
    );
  }
}

/// Le thème qui correspond au choix de l'utilisateur ; sombre tant qu'il n'a
/// pas choisi.
ThemeData themeFor(ThemeChoice? choice) =>
    buildAppTheme(choice == ThemeChoice.light ? Brightness.light : Brightness.dark);

/// Thème "table de jeu" : doré, plus proche d'un casino que d'un formulaire —
/// pensé pour un jeu de dés plutôt qu'une appli utilitaire. Sombre (feutre vert
/// profond) ou clair (feutre sauge pâle) selon [brightness].
ThemeData buildAppTheme([Brightness brightness = Brightness.dark]) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFFD9A441),
    brightness: brightness,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: [brightness == Brightness.dark ? TableColors.dark : TableColors.light],
    // Transparent : le feutre de table (CasinoFeltBackground, posé derrière
    // le Navigator dans main.dart) doit rester visible à travers chaque
    // Scaffold et sa barre d'app.
    scaffoldBackgroundColor: Colors.transparent,
    // Les écrans glissent comme des tuiles, chacun avec son feutre (voir
    // FeltTileSlidePageTransitionsBuilder) — plutôt que le fondu d'Android.
    pageTransitionsTheme: feltTileSlideTransitionsTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
        color: colorScheme.primary,
      ),
    ),
    textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
          headlineMedium: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
          headlineSmall: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
          titleLarge: const TextStyle(fontWeight: FontWeight.w800),
          titleMedium: const TextStyle(fontWeight: FontWeight.w700),
        ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary, width: 1.6),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primary,
      labelStyle: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
      secondaryLabelStyle: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
      shape: const StadiumBorder(),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: colorScheme.primary,
        selectedForegroundColor: colorScheme.onPrimary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerHigh,
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

/// Le facteur appliqué aux polices de l'application selon la plateforme : à
/// facteur de forme égal, les mêmes tailles logiques paraissent nettement plus
/// grandes sur iOS (police SF, taille de texte du système) que sur Android. Il
/// s'ajoute au réglage de taille de texte de l'appareil, qu'il ne remplace pas.
double textScaleFactorFor(TargetPlatform platform) => platform == TargetPlatform.iOS ? iosTextScaleFactor : 1.0;

/// Voir [textScaleFactorFor].
const double iosTextScaleFactor = 0.88;

/// Réduit les polices de [child] de [textScaleFactorFor] : rien à faire hors iOS.
Widget withPlatformTextScale(BuildContext context, Widget child) {
  final factor = textScaleFactorFor(Theme.of(context).platform);
  if (factor == 1.0) return child;
  final media = MediaQuery.of(context);
  return MediaQuery(
    data: media.copyWith(textScaler: TextScaler.linear(media.textScaler.scale(1.0) * factor)),
    child: child,
  );
}
