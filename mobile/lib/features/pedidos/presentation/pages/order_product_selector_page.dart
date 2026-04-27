import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/order_model.dart';
import '../cubit/orders_cubit.dart';

class OrderProductSelectorPage extends StatefulWidget {
  const OrderProductSelectorPage({super.key});

  @override
  State<OrderProductSelectorPage> createState() => _OrderProductSelectorPageState();
}

class _OrderProductSelectorPageState extends State<OrderProductSelectorPage> {
  final _search = TextEditingController();
  List<OrderProductLookup> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final items = await context.read<OrdersCubit>().searchProducts(_search.text.trim());
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar productos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => _runSearch(),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Nombre, código o barras'),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final p = _items[i];
                final isOutOfStock = !p.hasVariants && p.stockCurrent <= 0;
                return ListTile(
                  enabled: !isOutOfStock,
                  title: Row(
                    children: [
                      Expanded(child: Text(p.name)),
                      if (isOutOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('Sin stock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                    ],
                  ),
                  subtitle: Text(
                    '${p.internalCode ?? '-'} · Stock ${p.stockCurrent.toStringAsFixed(0)} · ${p.salePrice.toStringAsFixed(2)}${p.hasVariants ? ' · Con variantes' : ''}',
                  ),
                  onTap: isOutOfStock ? null : () => _selectProduct(p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectProduct(OrderProductLookup product) async {
    if (!product.hasVariants) {
      Navigator.pop(context, [OrderProductSelection(product: product)]);
      return;
    }

    final variants = await context.read<OrdersCubit>().searchProductVariants(product.id);
    if (!mounted) return;
    final activeVariants = variants.where((v) => v.active).toList();

    if (activeVariants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El producto tiene variantes pero no hay variantes activas.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<List<OrderProductSelection>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _VariantMultiSelectSheet(product: product, variants: activeVariants),
    );

    if (selected != null && selected.isNotEmpty && mounted) {
      Navigator.pop(context, selected);
    }
  }
}

class _VariantMultiSelectSheet extends StatefulWidget {
  const _VariantMultiSelectSheet({required this.product, required this.variants});

  final OrderProductLookup product;
  final List<OrderProductVariantLookup> variants;

  @override
  State<_VariantMultiSelectSheet> createState() => _VariantMultiSelectSheetState();
}

class _VariantMultiSelectSheetState extends State<_VariantMultiSelectSheet> {
  late final Map<String, int> _quantities;

  @override
  void initState() {
    super.initState();
    _quantities = {for (final v in widget.variants) v.id: 0};
  }

  @override
  Widget build(BuildContext context) {
    final totalSelected = _quantities.values.fold<int>(0, (a, b) => a + b);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Variantes de ${widget.product.name}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.variants.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final v = widget.variants[i];
                final qty = _quantities[v.id] ?? 0;
                final stock = (v.effectiveStock ?? 0).floor();
                final price = v.effectivePrice ?? widget.product.salePrice;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('Stock ${stock.toStringAsFixed(0)} · ${price.toStringAsFixed(2)}${stock <= 0 ? ' · Sin stock' : ''}'),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: qty > 0 ? () => setState(() => _quantities[v.id] = qty - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      SizedBox(width: 28, child: Text('$qty', textAlign: TextAlign.center)),
                      IconButton(
                        onPressed: stock <= 0 ? null : (qty < stock ? () => setState(() => _quantities[v.id] = qty + 1) : null),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final picked = widget.variants
                    .where((v) => (_quantities[v.id] ?? 0) > 0)
                    .map((v) => OrderProductSelection(product: widget.product, variant: v, initialQuantity: (_quantities[v.id] ?? 0).toDouble()))
                    .toList();
                if (picked.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccioná al menos una variante con cantidad mayor a 0.')),
                  );
                  return;
                }
                Navigator.pop(context, picked);
              },
              child: Text('Agregar seleccionadas ($totalSelected)'),
            ),
          ),
        ],
      ),
    );
  }
}
