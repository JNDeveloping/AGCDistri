import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/order_model.dart';
import '../cubit/orders_cubit.dart';
import 'order_client_selector_page.dart';
import 'order_product_selector_page.dart';

class OrderFormPage extends StatefulWidget {
  const OrderFormPage({this.orderId, super.key});

  final String? orderId;

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  OrderClientLookup? _client;
  final _notes = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _discountTotal = TextEditingController(text: '0');
  final _taxTotal = TextEditingController(text: '0');
  final Map<String, _CartLine> _cart = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _loadExisting();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = _cart.values.fold<double>(0, (acc, l) => acc + (l.product.salePrice * l.quantity));
    final total = subtotal - (double.tryParse(_discountTotal.text) ?? 0) + (double.tryParse(_taxTotal.text) ?? 0);

    final creditWarning = _client != null && _client!.creditLimit > 0 && (_client!.currentBalance + total) > _client!.creditLimit;

    return Scaffold(
      appBar: AppBar(title: Text(widget.orderId == null ? 'Nuevo pedido' : 'Editar pedido')),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Row(
          children: [
            Expanded(child: Text('Subtotal: ${subtotal.toStringAsFixed(2)}\nTotal: ${total.toStringAsFixed(2)}')),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Guardando...' : 'Guardar pedido')),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ListTile(
            title: Text(_client?.businessName ?? 'Seleccionar cliente'),
            subtitle: _client == null ? null : Text('Saldo ${_client!.currentBalance.toStringAsFixed(2)} · Límite ${_client!.creditLimit.toStringAsFixed(2)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _selectClient,
          ),
          if (creditWarning)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Advertencia: este pedido supera el límite de crédito del cliente.', style: TextStyle(color: Colors.orange)),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Carrito (${_cart.length} productos)', style: Theme.of(context).textTheme.titleMedium)),
              TextButton.icon(onPressed: _addProduct, icon: const Icon(Icons.add), label: const Text('Agregar')),
            ],
          ),
          ..._cart.values.map((line) => Card(
                child: ListTile(
                  title: Text(line.product.name),
                  subtitle: Text('Precio ${line.product.salePrice.toStringAsFixed(2)} · Stock ${line.product.stockCurrent.toStringAsFixed(0)}'),
                  trailing: SizedBox(
                    width: 180,
                    child: Row(
                      children: [
                        IconButton(onPressed: () => _changeQty(line.product.id, line.quantity - 1), icon: const Icon(Icons.remove_circle_outline)),
                        Expanded(
                          child: TextFormField(
                            initialValue: line.quantity.toStringAsFixed(0),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            onFieldSubmitted: (v) => _changeQty(line.product.id, double.tryParse(v) ?? line.quantity),
                          ),
                        ),
                        IconButton(onPressed: () => _changeQty(line.product.id, line.quantity + 1), icon: const Icon(Icons.add_circle_outline)),
                        IconButton(onPressed: () => _cart.remove(line.product.id), icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 8),
          TextField(controller: _discountTotal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Descuento general')),
          TextField(controller: _taxTotal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Impuestos')),
          TextField(controller: _paymentTerms, decoration: const InputDecoration(labelText: 'Condición de pago')),
          TextField(controller: _deliveryAddress, decoration: const InputDecoration(labelText: 'Dirección de entrega')),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Observaciones')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _selectClient() async {
    final selected = await Navigator.push<OrderClientLookup>(context, MaterialPageRoute(builder: (_) => const OrderClientSelectorPage()));
    if (selected != null) setState(() => _client = selected);
  }

  Future<void> _addProduct() async {
    final selected = await Navigator.push<OrderProductLookup>(context, MaterialPageRoute(builder: (_) => const OrderProductSelectorPage()));
    if (selected == null) return;
    setState(() {
      final existing = _cart[selected.id];
      _cart[selected.id] = _CartLine(product: selected, quantity: (existing?.quantity ?? 0) + 1);
    });
  }

  void _changeQty(String id, double value) {
    if (!_cart.containsKey(id)) return;
    if (value <= 0) {
      setState(() => _cart.remove(id));
      return;
    }
    setState(() => _cart[id] = _CartLine(product: _cart[id]!.product, quantity: value));
  }

  Future<void> _save() async {
    if (_client == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccioná un cliente.')));
      return;
    }
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agregá productos al carrito.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final items = _cart.values.map((l) => OrderItemInput(productId: l.product.id, quantity: l.quantity)).toList();
      await context.read<OrdersCubit>().save(
            id: widget.orderId,
            clientId: _client!.id,
            items: items,
            discountTotal: double.tryParse(_discountTotal.text) ?? 0,
            taxTotal: double.tryParse(_taxTotal.text) ?? 0,
            paymentTerms: _paymentTerms.text.trim().isEmpty ? null : _paymentTerms.text.trim(),
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            deliveryAddress: _deliveryAddress.text.trim().isEmpty ? null : _deliveryAddress.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CartLine {
  _CartLine({required this.product, required this.quantity});
  final OrderProductLookup product;
  final double quantity;
}
