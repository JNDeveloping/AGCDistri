import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/order_repository.dart';
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
  final _discountPercent = TextEditingController(text: '0');
  final Map<String, _CartLine> _cart = {};
  bool _saving = false;
  String _paymentTerms = 'contado';

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) _loadExisting();
  }

  @override
  void dispose() {
    _notes.dispose();
    _discountPercent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final subtotal = _cart.values.fold<double>(0, (acc, l) => acc + l.netSubtotal);
    final hasInvalidItems = _cart.values.any((line) => !line.isValidStock);
    final discountPercent = (double.tryParse(_discountPercent.text) ?? 0).clamp(0, 100);
    final discountTotal = subtotal * (discountPercent / 100);
    final total = subtotal - discountTotal;
    final creditWarning = _client != null && _client!.creditLimit > 0 && (_client!.currentBalance + total) > _client!.creditLimit;

    return Scaffold(
      appBar: AppBar(title: Text(widget.orderId == null ? 'Nuevo pedido' : 'Editar pedido')),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(color: color.surfaceContainerHighest, boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)]),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Subtotal: ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Total: ${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, color: color.primary, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            FilledButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: Text(_saving ? 'Guardando...' : 'Guardar')),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront),
              title: Text(_client?.businessName ?? 'Seleccionar cliente'),
              subtitle: _client == null
                  ? const Text('Tocá para elegir cliente')
                  : Text('Saldo ${_client!.currentBalance.toStringAsFixed(2)} · Límite ${_client!.creditLimit.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectClient,
            ),
          ),
          if (_client != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Dirección de entrega: se usa automáticamente la del cliente.', style: TextStyle(color: color.onSurfaceVariant)),
            ),
          if (creditWarning)
            const Card(
              color: Color(0xFFFFF3CD),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text('Advertencia: este pedido supera el límite de crédito del cliente.'),
              ),
            ),
          if (hasInvalidItems)
            const Card(
              color: Color(0xFFFFECEC),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Text('Hay productos sin stock o con cantidad mayor al disponible. Corregí el carrito para poder guardar.'),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Carrito (${_cart.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
              FilledButton.tonalIcon(onPressed: _addProduct, icon: const Icon(Icons.add), label: const Text('Agregar producto')),
            ],
          ),
          const SizedBox(height: 8),
          ..._cart.values.map(_itemCard),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _paymentTerms,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Condición de pago'),
                    items: const [
                      DropdownMenuItem(value: 'contado', child: Text('Contado')),
                      DropdownMenuItem(value: 'cuenta_corriente', child: Text('Cuenta corriente')),
                    ],
                    onChanged: (v) => setState(() => _paymentTerms = v ?? 'contado'),
                  ),
                  TextField(
                    controller: _discountPercent,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Descuento general (%)'),
                    onChanged: (_) => setState(() {}),
                  ),
                  TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Observaciones')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(_CartLine line) {
    final canIncrease = line.stock > 0 && line.quantity < line.stock;
    final canDecrease = line.quantity > 1;
    final isInvalid = !line.isValidStock;
    return Card(
      key: ValueKey('cart-item-${line.key}'),
      color: isInvalid ? const Color(0xFFFFF1F1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.displayName,
                    style: TextStyle(fontWeight: FontWeight.w700, color: isInvalid ? Colors.grey.shade700 : null),
                  ),
                ),
                if (isInvalid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(999)),
                    child: const Text('Sin stock', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
              ],
            ),
            Text('Precio unitario: ${line.unitPrice.toStringAsFixed(2)} · Stock ${line.stock.toStringAsFixed(0)}'),
            if (isInvalid)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Sin stock disponible', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(onPressed: canDecrease ? () => _changeQty(line.key, line.quantity - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          key: ValueKey('qty-${line.key}-${line.quantity.toStringAsFixed(2)}'),
                          initialValue: line.quantity.toStringAsFixed(0),
                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onFieldSubmitted: (v) => _changeQty(line.key, double.tryParse(v) ?? line.quantity),
                        ),
                      ),
                      IconButton(onPressed: canIncrease ? () => _changeQty(line.key, line.quantity + 1) : null, icon: const Icon(Icons.add_circle_outline)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: line.discountType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Desc.'),
                    items: const [
                      DropdownMenuItem(value: 'amount', child: Text('Monto')),
                      DropdownMenuItem(value: 'percentage', child: Text('%')),
                    ],
                    onChanged: (v) => _changeDiscountType(line.key, v ?? 'amount'),
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: TextFormField(
                    key: ValueKey('discount-${line.key}-${line.discountValue.toStringAsFixed(2)}'),
                    initialValue: line.discountValue.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.black),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor'),
                    onFieldSubmitted: (v) => _changeDiscountValue(line.key, double.tryParse(v) ?? 0),
                  ),
                ),
                IconButton(onPressed: () => setState(() => _cart.remove(line.key)), icon: const Icon(Icons.delete_outline)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Final ítem: ${line.netSubtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Future<void> _selectClient() async {
    final selected = await Navigator.push<OrderClientLookup>(context, MaterialPageRoute(builder: (_) => const OrderClientSelectorPage()));
    if (selected != null) setState(() => _client = selected);
  }

  Future<void> _loadExisting() async {
    final order = await context.read<OrdersCubit>().getById(widget.orderId!);
    if (!mounted) return;

    setState(() {
      _client = OrderClientLookup(id: order.clientId, businessName: order.clientName, currentBalance: 0, creditLimit: 0);
      _notes.text = order.notes ?? '';
      _paymentTerms = order.paymentTerms ?? 'contado';
      _discountPercent.text = order.subtotal > 0 ? ((order.discountTotal / order.subtotal) * 100).toStringAsFixed(2) : '0';
      _cart
        ..clear()
        ..addEntries(
          order.items.map(
            (i) {
              final product = OrderProductLookup(id: i.productId, name: i.productName, salePrice: i.unitPrice);
              final variant = i.productVariantId == null
                  ? null
                  : OrderProductVariantLookup(id: i.productVariantId!, productId: i.productId, name: i.variantNameSnapshot ?? '-', active: true, effectivePrice: i.unitPrice);
              final selection = OrderProductSelection(product: product, variant: variant, initialQuantity: i.quantity);
              return MapEntry(
                selection.cartKey,
                _CartLine(
                  key: selection.cartKey,
                  selection: selection,
                  quantity: i.quantity,
                  discountType: i.discountType,
                  discountValue: i.discountValue,
                ),
              );
            },
          ),
        );
    });
  }

  Future<void> _addProduct() async {
    final selected = await Navigator.push<List<OrderProductSelection>>(context, MaterialPageRoute(builder: (_) => const OrderProductSelectorPage()));
    if (selected == null || selected.isEmpty) return;

    bool addedAny = false;
    for (final selection in selected) {
      final existing = _cart[selection.cartKey];
      final increment = selection.initialQuantity <= 0 ? 1 : selection.initialQuantity;
      final nextQty = (existing?.quantity ?? 0) + increment;
      if (!_hasStockFor(selection, nextQty)) {
        final available = _availableFor(selection);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock insuficiente para ${selection.displayName}. Disponible: ${available.toStringAsFixed(0)}.')),
        );
        continue;
      }

      addedAny = true;
      _cart[selection.cartKey] = _CartLine(
        key: selection.cartKey,
        selection: selection,
        quantity: nextQty,
        discountType: existing?.discountType ?? 'amount',
        discountValue: existing?.discountValue ?? 0,
      );
    }

    if (!addedAny) return;
    setState(() {});
  }

  void _changeQty(String key, double value) {
    final line = _cart[key];
    if (line == null) return;
    if (value <= 0) return setState(() => _cart.remove(key));
    if (!_hasStockFor(line.selection, value)) {
      final available = _availableFor(line.selection);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuficiente para ${line.displayName}. Disponible: ${available.toStringAsFixed(0)}.')),
      );
      return;
    }
    setState(() => _cart[key] = line.copyWith(quantity: value));
  }

  void _changeDiscountType(String key, String type) {
    final line = _cart[key];
    if (line == null) return;
    setState(() => _cart[key] = line.copyWith(discountType: type));
  }

  void _changeDiscountValue(String key, double value) {
    final line = _cart[key];
    if (line == null) return;
    setState(() => _cart[key] = line.copyWith(discountValue: value));
  }

  bool _hasStockFor(OrderProductSelection selection, double quantity) {
    return quantity <= _availableFor(selection);
  }

  double _availableFor(OrderProductSelection selection) {
    return selection.effectiveStock;
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
    if (_cart.values.any((line) => !line.isValidStock)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hay productos sin stock o con cantidad mayor al disponible.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final subtotal = _cart.values.fold<double>(0, (acc, l) => acc + l.netSubtotal);
      final items = _cart.values
          .map((l) => OrderItemInput(productId: l.selection.product.id, productVariantId: l.selection.variant?.id, quantity: l.quantity, discountType: l.discountType, discountValue: l.discountValue))
          .toList();
      await context.read<OrdersCubit>().save(
            id: widget.orderId,
            clientId: _client!.id,
            items: items,
            discountTotal: subtotal * (((double.tryParse(_discountPercent.text) ?? 0).clamp(0, 100)) / 100),
            paymentTerms: _paymentTerms,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } on OrderException catch (e) {
      if (!mounted) return;
      if (e.isInsufficientStock) {
        final itemName = [e.productName, e.variantName].whereType<String>().where((v) => v.trim().isNotEmpty).join(' - ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock insuficiente para ${itemName.isEmpty ? 'un producto' : itemName}. Disponible: ${(e.availableStock ?? 0).toStringAsFixed(0)}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar el pedido.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CartLine {
  _CartLine({required this.key, required this.selection, required this.quantity, this.discountType = 'amount', this.discountValue = 0});

  final String key;
  final OrderProductSelection selection;
  final double quantity;
  final String discountType;
  final double discountValue;

  String get displayName => selection.displayName;
  double get unitPrice => selection.effectivePrice;
  double get stock => selection.effectiveStock;
  bool get isValidStock => stock > 0 && quantity <= stock;

  double get discountAmount {
    if (discountType == 'percentage') {
      return (unitPrice * quantity * discountValue) / 100;
    }
    return discountValue;
  }

  double get netSubtotal => isValidStock ? (unitPrice * quantity - discountAmount).clamp(0, double.infinity) : 0;

  _CartLine copyWith({double? quantity, String? discountType, double? discountValue}) => _CartLine(
        key: key,
        selection: selection,
        quantity: quantity ?? this.quantity,
        discountType: discountType ?? this.discountType,
        discountValue: discountValue ?? this.discountValue,
      );
}
