import 'package:flutter/material.dart';

import '../../domain/models/stock_models.dart';

class StockProductCard extends StatelessWidget {
  const StockProductCard({required this.item, required this.onTap, super.key});

  final StockItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, label) = switch (item.status) {
      'sin_stock' => (Colors.red.shade100, 'Sin stock'),
      'stock_bajo' => (Colors.amber.shade100, 'Stock bajo'),
      _ => (Colors.green.shade100, 'Normal'),
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)), child: Text(label))]),
              const SizedBox(height: 6),
              Text('Código: ${item.internalCode ?? '-'} · Categoría: ${item.categoryName ?? '-'}'),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: Text('Stock actual: ${item.stockCurrent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                Text('Mínimo: ${item.stockMinimum.toStringAsFixed(2)}'),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
