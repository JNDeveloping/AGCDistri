import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/order_model.dart';
import '../cubit/orders_cubit.dart';

class OrderClientSelectorPage extends StatefulWidget {
  const OrderClientSelectorPage({super.key});

  @override
  State<OrderClientSelectorPage> createState() => _OrderClientSelectorPageState();
}

class _OrderClientSelectorPageState extends State<OrderClientSelectorPage> {
  final _search = TextEditingController();
  List<OrderClientLookup> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _runSearch();
  }

  Future<void> _runSearch() async {
    setState(() => _loading = true);
    final items = await context.read<OrdersCubit>().searchClients(_search.text.trim());
    if (mounted) setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar cliente')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: (_) => _runSearch(),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar cliente por nombre o código'),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final c = _items[i];
                return ListTile(
                  title: Text(c.businessName),
                  subtitle: Text('Saldo: ${c.currentBalance.toStringAsFixed(2)} · Límite: ${c.creditLimit.toStringAsFixed(2)}'),
                  onTap: () => Navigator.pop(context, c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
