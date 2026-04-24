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
    if (mounted) setState(() {
      _items = items;
      _loading = false;
    });
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
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('${p.internalCode ?? '-'} · Stock ${p.stockCurrent.toStringAsFixed(0)} · ${p.salePrice.toStringAsFixed(2)}'),
                  onTap: () => Navigator.pop(context, p),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
