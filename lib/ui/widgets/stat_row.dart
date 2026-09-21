import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import 'die_widget.dart';

/// « dont ⚃  2 » : une valeur de dé et son compte, en retrait sous le total de
/// la figure. Le dé est dessiné plutôt qu'écrit en chiffres — c'est l'objet dont
/// on parle, et [DieGlyph] reste lisible à cette taille là où le cube 3D ne
/// l'est pas.
class BreakdownRow extends StatelessWidget {
  final int value;
  final int count;

  const BreakdownRow({super.key, required this.value, required this.count});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2),
      child: Row(
        children: [
          Text('– ${l10n.statsBreakdownRow} ', style: style),
          DieGlyph(value: value, size: 14),
          const Spacer(),
          Text('$count', style: style),
        ],
      ),
    );
  }
}

class StatRow extends StatelessWidget {
  final String label;
  final String value;

  const StatRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
          Text(value),
        ],
      ),
    );
  }
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
