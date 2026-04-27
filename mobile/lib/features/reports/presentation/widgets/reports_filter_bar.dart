import 'package:flutter/material.dart';

class ReportsFilterBar extends StatelessWidget {
  const ReportsFilterBar({
    required this.period,
    required this.onPeriodChanged,
    super.key,
  });

  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in const [
          ('today', 'Hoy'),
          ('week', 'Esta semana'),
          ('month', 'Este mes'),
        ])
          ChoiceChip(
            label: Text(p.$2),
            selected: period == p.$1,
            onSelected: (_) => onPeriodChanged(p.$1),
          ),
      ],
    );
  }
}
