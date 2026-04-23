import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle producto')),
      body: FutureBuilder<ProductModel>(
        future: context.read<ProductsCubit>().getById(productId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
              Text('${p.internalCode} · ${p.brand} · ${p.category}'),
              const SizedBox(height: 12),
              Text(p.shortDescription),
              if (p.longDescription != null) Text(p.longDescription!),
              const Divider(height: 30),
              Text('Costo: ${(p.cost ?? 0).toStringAsFixed(2)}'),
              Text('Mayorista: ${(p.wholesalePrice ?? 0).toStringAsFixed(2)}'),
              Text('Minorista: ${(p.retailPrice ?? 0).toStringAsFixed(2)}'),
              Text('Margen: ${(p.marginPercentage ?? 0).toStringAsFixed(2)}%'),
              const Divider(height: 30),
              Text('Stock actual: ${p.stockCurrent.toStringAsFixed(2)}'),
              Text('Stock mínimo: ${p.stockMinimum.toStringAsFixed(2)}'),
              Text('Estado: ${p.isActive ? 'Activo' : 'Inactivo'}'),
            ],
          );
        },
      ),
    );
  }
}
