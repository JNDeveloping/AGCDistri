import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';
import 'product_form_page.dart';
import '../../../stock/presentation/pages/stock_product_detail_page.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({required this.productId, super.key});

  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<ProductModel> _future;
  late Future<List<ProductVariantModel>> _variantsFuture;

  @override
  void initState() {
    super.initState();
    _future = context.read<ProductsCubit>().getById(widget.productId);
    _variantsFuture = context.read<ProductsCubit>().listVariants(widget.productId);
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
                  setState(() {
                    _future = context.read<ProductsCubit>().getById(widget.productId);
                    _variantsFuture = context.read<ProductsCubit>().listVariants(widget.productId);
                  });
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
              Text('Con variantes: ${p.hasVariants ? 'Sí' : 'No'}'),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StockProductDetailPage(productId: p.id)),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Ver historial de stock'),
              ),
              const SizedBox(height: 12),
              if (p.hasVariants) ...[
                Row(
                  children: [
                    const Expanded(child: Text('Variantes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    if (canEdit)
                      OutlinedButton.icon(
                        onPressed: () => _openVariantForm(p.id),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar variante'),
                      ),
                  ],
                ),
                FutureBuilder<List<ProductVariantModel>>(
                  future: _variantsFuture,
                  builder: (context, variantSnap) {
                    if (!variantSnap.hasData) return const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator());
                    final variants = variantSnap.data!;
                    if (variants.isEmpty) return const Text('No hay variantes cargadas.');
                    return Column(
                      children: variants.map((v) => Card(
                        child: ListTile(
                          title: Text(v.name),
                          subtitle: Text('Precio: ${(v.effectivePrice ?? 0).toStringAsFixed(2)} · Stock: ${(v.effectiveStock ?? 0).toStringAsFixed(0)}'),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              Chip(label: Text(v.active ? 'Activa' : 'Inactiva')),
                              if (canEdit) IconButton(onPressed: () => _openVariantForm(p.id, variant: v), icon: const Icon(Icons.edit_outlined)),
                              if (canEdit)
                                IconButton(
                                  onPressed: () async {
                                    await context.read<ProductsCubit>().setVariantActive(v.id, !v.active);
                                    if (!mounted) return;
                                    setState(() => _variantsFuture = context.read<ProductsCubit>().listVariants(widget.productId));
                                  },
                                  icon: Icon(v.active ? Icons.block_outlined : Icons.check_circle_outline),
                                ),
                            ],
                          ),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _openVariantForm(String productId, {ProductVariantModel? variant}) async {
    final nameCtrl = TextEditingController(text: variant?.name ?? '');
    final codeCtrl = TextEditingController(text: variant?.internalCode ?? '');
    final barcodeCtrl = TextEditingController(text: variant?.barcode ?? '');
    final priceCtrl = TextEditingController(text: variant?.price?.toString() ?? '');
    final costCtrl = TextEditingController(text: variant?.cost?.toString() ?? '');
    final stockCtrl = TextEditingController(text: variant?.stock?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(variant == null ? 'Nueva variante' : 'Editar variante'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Código interno')),
              TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Código barras')),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Precio'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: costCtrl, decoration: const InputDecoration(labelText: 'Costo'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;

    await context.read<ProductsCubit>().saveVariant(
      productId,
      ProductVariantModel(
        id: variant?.id ?? 'new',
        productId: productId,
        name: nameCtrl.text.trim(),
        internalCode: codeCtrl.text.trim().isEmpty ? null : codeCtrl.text.trim(),
        barcode: barcodeCtrl.text.trim().isEmpty ? null : barcodeCtrl.text.trim(),
        price: double.tryParse(priceCtrl.text.trim().replaceAll(',', '.')),
        cost: double.tryParse(costCtrl.text.trim().replaceAll(',', '.')),
        stock: double.tryParse(stockCtrl.text.trim().replaceAll(',', '.')),
        active: variant?.active ?? true,
      ),
      variantId: variant?.id,
    );

    if (!mounted) return;
    setState(() => _variantsFuture = context.read<ProductsCubit>().listVariants(widget.productId));
  }
}
