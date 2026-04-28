import 'package:flutter/material.dart';

import '../../domain/models/stock_models.dart';

class StockProductCard extends StatelessWidget {
  const StockProductCard({required this.item, required this.onTap, super.key});

  final StockItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusStyle(item.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: status.border.withValues(alpha: 0.4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: status.bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(status.label, style: TextStyle(color: status.fg, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Código: ${item.internalCode ?? '-'} · Categoría: ${item.categoryName ?? '-'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              if (item.hasVariants && item.variants.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.variants
                      .where((v) => v.isActive)
                      .map((v) => Chip(
                            label: Text('${v.name}: ${(v.stock ?? item.stockCurrent).toStringAsFixed(0)}'),
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stock actual', style: Theme.of(context).textTheme.labelMedium),
                        Text(
                          item.stockCurrent.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: status.fg,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Stock mínimo', style: Theme.of(context).textTheme.labelMedium),
                      Text(
                        item.stockMinimum.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _StockStatusStyle _statusStyle(String status) {
    if (status == 'sin_stock') {
      return _StockStatusStyle(
        label: 'Sin stock',
        bg: Colors.red.shade50,
        fg: Colors.red.shade800,
        border: Colors.red.shade300,
      );
    }

    if (status == 'stock_bajo') {
      return _StockStatusStyle(
        label: 'Stock bajo',
        bg: Colors.amber.shade50,
        fg: Colors.amber.shade900,
        border: Colors.amber.shade400,
      );
    }

    return _StockStatusStyle(
      label: 'Normal',
      bg: Colors.green.shade50,
      fg: Colors.green.shade800,
      border: Colors.green.shade300,
    );
  }
}

class _StockStatusStyle {
  const _StockStatusStyle({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
  });

  final String label;
  final Color bg;
  final Color fg;
  final Color border;
}
