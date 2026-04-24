import 'package:flutter/material.dart';

import '../../domain/models/product_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDeactivate,
    required this.canEdit,
    super.key,
  });

  final ProductModel product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(product.name),
        subtitle: Text('${product.internalCode ?? '-'} · ${product.brand ?? '-'} · Stock: ${product.stockCurrent.toStringAsFixed(2)}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Venta ${product.salePrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (product.lowStock)
              const Text('Stock bajo', style: TextStyle(color: Colors.red, fontSize: 12))
            else if (!product.isActive)
              const Text('Inactivo', style: TextStyle(color: Colors.orange, fontSize: 12)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
