import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';
import 'die_widget.dart';

/// « dont ⚃  2 » : une valeur de dé et son compte, en retrait sous le total de
/// la figure. Le dé est dessiné plutôt qu'écrit en chiffres — c'est l'objet dont
/// on parle, et [DieGlyph] reste lisible à cette taille là où le cube 3D ne
/// l'est pas.
class BreakdownRow extends StatelessWidget {
  final int value;
  final int count;

  /// Le total de la figure dont cette valeur est une part : le compte est alors
  /// suivi de sa part en pourcentage (voir [withShare]).
  final int? total;

  /// Ce qui s'affiche à droite à la place de [count] : un record y ajoute ceux
  /// qui le détiennent (voir `StatisticsScreen`).
  final String? display;

  const BreakdownRow({super.key, required this.value, required this.count, this.total, this.display});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    final shown = display ??
        (total == null ? '$count' : withShare(count, total!, Localizations.localeOf(context).toString()));
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      child: Row(
        children: [
          Text('– ${l10n.statsBreakdownRow} ', style: style),
          DieGlyph(value: value, size: 14),
          Expanded(child: Text(shown, style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

/// Une ligne de statistique dont le détail se déplie : le libellé suivi d'un
/// chevron, la valeur à droite comme sur toute autre ligne, et dessous les lignes
/// de détail ([children]) une fois dépliée. Repliée par défaut : le détail d'une
/// figure fait six lignes, et trois figures à la suite encombraient l'écran.
///
/// Le chevron suit le libellé plutôt que de s'aligner à droite : les valeurs
/// restent ainsi alignées avec celles des lignes voisines, qui n'ont pas de
/// détail.
class ExpandableStatRow extends StatefulWidget {
  final String label;
  final String value;
  final List<Widget> children;
  final bool initiallyExpanded;

  const ExpandableStatRow({
    super.key,
    required this.label,
    required this.value,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableStatRow> createState() => _ExpandableStatRowState();
}

class _ExpandableStatRowState extends State<ExpandableStatRow> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(widget.label, style: style),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Icon(Icons.expand_more, size: 18, color: style?.color),
                  ),
                  const Spacer(),
                  Text(widget.value),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...widget.children,
      ],
    );
  }
}

class StatRow extends StatelessWidget {
  final String label;
  final String value;

  /// Le détail d'une ligne qui précède (« – dont petites ») : mis en retrait et
  /// précédé du même tiret que [BreakdownRow], pour que toutes les ventilations
  /// se lisent pareil, qu'elles portent sur une valeur de dé ou sur autre chose.
  /// Le tiret est posé ici plutôt que dans les libellés, qui restent des mots.
  final bool detail;

  const StatRow({super.key, required this.label, required this.value, this.detail = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: detail ? 12 : 0, top: 2, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(detail ? '– $label' : label, style: Theme.of(context).textTheme.bodySmall),
          ),
          // Un détail se lit dans la même taille que les lignes de dés
          // (`BreakdownRow`), sans quoi sa valeur, suivie de sa part, dépasserait
          // celle des lignes voisines.
          Text(value, style: detail ? Theme.of(context).textTheme.bodySmall : null),
        ],
      ),
    );
  }
}

/// Moyenne à une décimale, au séparateur de la langue : « 2,4 » en français.
/// `null` (aucun tour, donc aucune moyenne) s'affiche en tiret plutôt qu'en
/// zéro, qui se lirait « aucun lancer par tour ».
String formatAverage(double? value, String locale) {
  if (value == null) return '—';
  return NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 1).format(value);
}

/// Durée lisible : « 1 h 05 », « 12 min », « 45 s ». `null` (aucune partie)
/// s'affiche en tiret plutôt qu'en zéro, qui se lirait « instantané ».
String formatDuration(int? seconds) {
  if (seconds == null) return '—';
  if (seconds < 60) return '$seconds s';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
}

/// « 37,50 % » : la part de [count] dans [total], à deux décimales, au séparateur
/// de la langue. Nul quand il n'y a rien à répartir ([total] à zéro) : une part
/// de rien n'existe, ce n'est pas 0 %.
String? formatShare(int count, int total, String locale) {
  if (total <= 0) return null;
  final percent = NumberFormat.decimalPatternDigits(locale: locale, decimalDigits: 2).format(count * 100 / total);
  return '$percent %';
}

/// « 3 (37,50 %) » : le compte suivi de sa part du total, entre parenthèses.
/// Sans total à répartir, le compte seul.
String withShare(int count, int total, String locale) {
  final share = formatShare(count, total, locale);
  return share == null ? '$count' : '$count ($share)';
}
