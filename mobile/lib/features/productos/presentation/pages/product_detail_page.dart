import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';
import 'product_form_page.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.productId, super.key});

  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<ProductModel> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ProductsCubit>().getById(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canEdit = role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle producto'),
        actions: [
          if (canEdit)
            IconButton(
              onPressed: () async {
                final product = await _future;
                if (!mounted) return;
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
                );
                if (changed == true && mounted) {
                  setState(() => _future = context.read<ProductsCubit>().getById(widget.productId));
                }
              },
              icon: const Icon(Icons.edit_rounded),
            ),
        ],
      ),
      body: FutureBuilder<ProductModel>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data!;
          final subtitleParts = [
            if ((p.internalCode ?? '').isNotEmpty) p.internalCode!,
            if ((p.brand ?? '').isNotEmpty) p.brand!,
            if ((p.categoryName ?? '').isNotEmpty) p.categoryName!,
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
              Text(subtitleParts.join(' · ')),
              const SizedBox(height: 12),
              if ((p.shortDescription ?? '').isNotEmpty) Text(p.shortDescription!),
              if (p.longDescription != null) Text(p.longDescription!),
              const Divider(height: 30),
              Text('Costo: ${(p.cost ?? 0).toStringAsFixed(2)}'),
              Text('Precio de venta: ${p.salePrice.toStringAsFixed(2)}'),
              Text('Margen: ${(p.marginPercentage ?? 0).toStringAsFixed(2)}%'),
              if ((p.barcode ?? '').isNotEmpty) Text('Código de barras: ${p.barcode}'),
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
