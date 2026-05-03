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
  bool _loadingSmart = false;
  String? _stockAdjustmentNotice;
  String _paymentTerms = 'contado';
  double? _serverSubtotal;
  double? _serverDiscount;
  double? _serverTotal;

  List<ClientPurchaseHistoryItem> _purchaseHistory = const [];
  List<SuggestedProductItem> _suggestedProducts = const [];
  ClientLastOrderSuggestion? _lastOrder;

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
    final subtotal = _serverSubtotal ?? _cart.values.fold<double>(0, (acc, l) => acc + l.netSubtotal);
    final hasInvalidItems = _cart.values.any((line) => !line.isValidStock);
    final discountPercent = (double.tryParse(_discountPercent.text) ?? 0).clamp(0, 100);
    final discountTotal = _serverDiscount ?? (subtotal * (discountPercent / 100));
    final total = _serverTotal ?? (subtotal - discountTotal);

    return Scaffold(
      appBar: AppBar(title: Text(widget.orderId == null ? 'Nuevo pedido' : 'Editar pedido')),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: color.surfaceContainerHighest,
          boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Subtotal: ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    'Total: ${total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 18, color: color.primary, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_saving ? 'Guardando...' : 'Guardar'),
            ),
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
          if (_client != null) ...[
            const SizedBox(height: 8),
            _smartActions(),
            const SizedBox(height: 8),
            _purchaseHistorySection(),
            const SizedBox(height: 8),
            _suggestionsSection(),
          ],
          if (hasInvalidItems)
            const Card(color: Color(0xFFFFECEC), child: Padding(padding: EdgeInsets.all(10), child: Text('Hay líneas con stock insuficiente.'))),
          if (_stockAdjustmentNotice != null)
            Card(
              color: const Color(0xFFFFF7E8),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(_stockAdjustmentNotice!, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Carrito (${_cart.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Agregar producto'),
              ),
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

  Widget _smartActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pedido inteligente', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: (_lastOrder?.items.isEmpty ?? true) ? null : _repeatLastOrder,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Repetir último pedido'),
                ),
                OutlinedButton.icon(
                  onPressed: _suggestedProducts.isEmpty ? null : _generateSuggestedOrder,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generar pedido sugerido'),
                ),
                if (_loadingSmart) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _purchaseHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comprados anteriormente', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (_purchaseHistory.isEmpty)
              const Text('Sin historial todavía para este cliente.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _purchaseHistory
                    .map(
                      (h) => Chip(
                        label: Text(
                          '${h.productName}${h.variantName != null ? ' - ${h.variantName}' : ''} · Prom ${h.averageQuantity.toStringAsFixed(1)} · ${h.frequency}',
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Productos sugeridos', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (_suggestedProducts.isEmpty)
              const Text('No hay sugerencias con stock disponible por ahora.')
            else
              ..._suggestedProducts.take(10).map(
                    (s) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text('${s.productName}${s.variantName != null ? ' - ${s.variantName}' : ''}'),
                      subtitle: Text(
                        'Stock ${s.stockAvailable.toStringAsFixed(0)} · ${s.currentPrice.toStringAsFixed(2)} · ${_reasonLabel(s.relevanceReason)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle_rounded),
                        onPressed: () => _addFromSuggestion(s),
                      ),
                    ),
                  ),
          ],
        ),
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
            Row(children:[if(line.hasPromo)...[Text(line.originalUnitPrice.toStringAsFixed(2),style:const TextStyle(decoration: TextDecoration.lineThrough)),const SizedBox(width:6)],Text('Precio: ${line.unitPrice.toStringAsFixed(2)} · Stock ${line.stock.toStringAsFixed(0)}')]),
            if (line.hasPromo) Wrap(spacing:6,children:[Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:2),decoration:BoxDecoration(color:Colors.green.shade100,borderRadius:BorderRadius.circular(999)),child:const Text('Promo',style:TextStyle(fontWeight: FontWeight.w700,fontSize: 12))),Text(line.promoText)]),
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
                          initialValue: line.quantity.toStringAsFixed(0),
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
                    initialValue: line.discountValue.toStringAsFixed(0),
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
    if (selected == null) return;
    setState(() => _client = selected);
    await _loadSmartData();
  }

  Future<void> _loadSmartData() async {
    if (_client == null) return;
    setState(() => _loadingSmart = true);
    try {
      final cubit = context.read<OrdersCubit>();
      final results = await Future.wait([
        cubit.getPurchaseHistory(_client!.id),
        cubit.getSuggestedProducts(_client!.id),
        cubit.getLastOrder(_client!.id),
      ]);
      if (!mounted) return;
      setState(() {
        _purchaseHistory = results[0] as List<ClientPurchaseHistoryItem>;
        _suggestedProducts = results[1] as List<SuggestedProductItem>;
        _lastOrder = results[2] as ClientLastOrderSuggestion;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudieron cargar sugerencias inteligentes.')));
      }
    } finally {
      if (mounted) setState(() => _loadingSmart = false);
    }
  }

  Future<void> _loadExisting() async {
    final order = await context.read<OrdersCubit>().getById(widget.orderId!);
    if (!mounted) return;

    final adjustedMessages = <String>[];
    final nextCart = <String, _CartLine>{};
    for (final item in order.items) {
      final product = OrderProductLookup(id: item.productId, name: item.productName, salePrice: item.unitPrice);
      double stock = 0;
      if (item.productVariantId != null) {
        final variants = await context.read<OrdersCubit>().searchProductVariants(item.productId);
        final matches = variants.where((v) => v.id == item.productVariantId);
        final variant = matches.isEmpty ? null : matches.first;
        stock = variant?.effectiveStock ?? 0;
      } else {
        final products = await context.read<OrdersCubit>().searchProducts(item.productName);
        final matches = products.where((p) => p.id == item.productId);
        final current = matches.isEmpty ? null : matches.first;
        stock = current?.stockCurrent ?? 0;
      }

      if (stock <= 0) {
        adjustedMessages.add('${item.productName}: sin stock, se quitó del pedido.');
        continue;
      }
      final adjustedQty = item.quantity > stock ? stock : item.quantity;
      if (adjustedQty != item.quantity) {
        adjustedMessages.add('${item.productName}: cantidad ajustada a ${adjustedQty.toStringAsFixed(0)}.');
      }

      final variant = item.productVariantId == null
          ? null
          : OrderProductVariantLookup(
              id: item.productVariantId!,
              productId: item.productId,
              name: item.variantNameSnapshot ?? '-',
              active: true,
              effectivePrice: item.unitPrice,
              effectiveStock: stock,
            );
      final selection = OrderProductSelection(
        product: OrderProductLookup(id: item.productId, name: item.productName, salePrice: item.unitPrice, stockCurrent: stock),
        variant: variant,
        initialQuantity: adjustedQty,
      );
      nextCart[selection.cartKey] = _CartLine(
        key: selection.cartKey,
        selection: selection,
        quantity: adjustedQty,
        discountType: item.discountType,
        discountValue: item.discountValue,
        originalUnitPrice: item.originalUnitPrice,
        promoText: _promotionSummary(item.appliedPromotions),
      );
    }

    setState(() {
      _client = OrderClientLookup(id: order.clientId, businessName: order.clientName, currentBalance: 0, creditLimit: 0);
      _notes.text = order.notes ?? '';
      _paymentTerms = order.paymentTerms ?? 'contado';
      _discountPercent.text = order.subtotal > 0 ? ((order.discountTotal / order.subtotal) * 100).toStringAsFixed(2) : '0';
      _cart
        ..clear()
        ..addAll(nextCart);
      _stockAdjustmentNotice = adjustedMessages.isEmpty ? null : 'Se ajustaron productos sin stock. Revisá el pedido antes de guardar.';
    });
    if (adjustedMessages.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(adjustedMessages.take(2).join(' '))));
    }
    await _loadSmartData();
  }


  String _promotionSummary(List<dynamic> appliedPromotions) {
    if (appliedPromotions.isEmpty) return '';
    final labels = appliedPromotions
        .whereType<Map<String, dynamic>>()
        .map((promo) => (promo['description'] ?? promo['name'] ?? promo['type'])?.toString().trim() ?? '')
        .where((label) => label.isNotEmpty)
        .toList();
    if (labels.isEmpty) return 'Promoción aplicada';
    return labels.take(2).join(' · ');
  }
  Future<void> _repeatLastOrder() async {
    final data = _lastOrder;
    if (data == null || data.items.isEmpty) return;

    final alerts = <String>[];
    for (final item in data.items) {
      if (!item.hasStock) alerts.add('Sin stock: ${item.productName}');
      if (item.priceChanged) alerts.add('Precio actualizado: ${item.productName}');

      if (!item.hasStock) continue;
      final selection = OrderProductSelection(
        product: OrderProductLookup(
          id: item.productId,
          name: item.productName,
          salePrice: item.currentPrice,
          stockCurrent: item.stockAvailable,
          hasVariants: item.hasVariants,
          hasActivePromotion: item.hasActivePromotion,
        ),
        variant: item.productVariantId == null
            ? null
            : OrderProductVariantLookup(
                id: item.productVariantId!,
                productId: item.productId,
                name: item.variantName ?? 'Variante',
                active: true,
                effectivePrice: item.currentPrice,
                effectiveStock: item.stockAvailable,
              ),
        initialQuantity: item.quantity,
      );
      _addSelectionToCart(selection, qty: item.quantity);
    }

    setState(() {});
    if (alerts.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(alerts.take(2).join(' · '))));
    }
  }

  void _generateSuggestedOrder() {
    for (final s in _suggestedProducts.where((e) => e.stockAvailable > 0).take(8)) {
      if (s.hasVariants && s.productVariantId == null) continue;
      final qty = (s.averageQuantity ?? 1).clamp(1, s.stockAvailable).toDouble();
      final selection = OrderProductSelection(
        product: OrderProductLookup(
          id: s.productId,
          name: s.productName,
          salePrice: s.currentPrice,
          stockCurrent: s.stockAvailable,
          hasVariants: s.hasVariants,
          hasActivePromotion: s.hasActivePromotion,
        ),
        variant: s.productVariantId == null
            ? null
            : OrderProductVariantLookup(
                id: s.productVariantId!,
                productId: s.productId,
                name: s.variantName ?? 'Variante',
                active: true,
                effectivePrice: s.currentPrice,
                effectiveStock: s.stockAvailable,
              ),
        initialQuantity: qty,
      );
      _addSelectionToCart(selection, qty: qty);
    }
    setState(() {});
  }

  Future<void> _addFromSuggestion(SuggestedProductItem suggestion) async {
    if (suggestion.stockAvailable <= 0) return;

    if (suggestion.hasVariants && suggestion.productVariantId == null) {
      final product = OrderProductLookup(
        id: suggestion.productId,
        name: suggestion.productName,
        salePrice: suggestion.currentPrice,
        hasVariants: true,
        hasActivePromotion: suggestion.hasActivePromotion,
      );
      await _selectProductWithVariants(product);
      return;
    }

    final selection = OrderProductSelection(
      product: OrderProductLookup(
        id: suggestion.productId,
        name: suggestion.productName,
        salePrice: suggestion.currentPrice,
        stockCurrent: suggestion.stockAvailable,
        hasVariants: suggestion.hasVariants,
        hasActivePromotion: suggestion.hasActivePromotion,
      ),
      variant: suggestion.productVariantId == null
          ? null
          : OrderProductVariantLookup(
              id: suggestion.productVariantId!,
              productId: suggestion.productId,
              name: suggestion.variantName ?? 'Variante',
              active: true,
              effectivePrice: suggestion.currentPrice,
              effectiveStock: suggestion.stockAvailable,
            ),
    );
    _addSelectionToCart(selection);
    setState(() {});
  }

  Future<void> _addProduct() async {
    final addedSimple = _cart.values
        .where((line) => line.selection.variant == null)
        .map((line) => line.selection.product.id)
        .toSet();
    final addedVariants = _cart.values
        .where((line) => line.selection.variant != null)
        .map((line) => line.selection.variant!.id)
        .toSet();

    final selected = await Navigator.push<List<OrderProductSelection>>(
      context,
      MaterialPageRoute(
        builder: (_) => OrderProductSelectorPage(
          addedSimpleProductIds: addedSimple,
          addedVariantIds: addedVariants,
        ),
      ),
    );
    if (selected == null || selected.isEmpty) return;
    for (final selection in selected) {
      _addSelectionToCart(selection, qty: selection.initialQuantity <= 0 ? 1 : selection.initialQuantity);
    }
    setState(() {});
  }

  Future<void> _selectProductWithVariants(OrderProductLookup product) async {
    final variants = await context.read<OrdersCubit>().searchProductVariants(product.id);
    if (!mounted) return;
    final activeVariants = variants.where((v) => v.active && (v.effectiveStock ?? 0) > 0).toList();
    if (activeVariants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay variantes con stock disponible.')));
      return;
    }

    final selected = await showModalBottomSheet<List<OrderProductSelection>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _VariantQuickSheet(product: product, variants: activeVariants),
    );
    if (selected == null || selected.isEmpty) return;
    for (final s in selected) {
      _addSelectionToCart(s, qty: s.initialQuantity);
    }
    setState(() {});
  }

  void _addSelectionToCart(OrderProductSelection selection, {double qty = 1}) {
    final existing = _cart[selection.cartKey];
    final nextQty = (existing?.quantity ?? 0) + qty;
    if (!_hasStockFor(selection, nextQty)) {
      final available = _availableFor(selection);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock insuficiente para ${selection.displayName}. Disponible: ${available.toStringAsFixed(0)}.')),
      );
      return;
    }

    _cart[selection.cartKey] = _CartLine(
      key: selection.cartKey,
      selection: selection,
      quantity: nextQty,
      discountType: existing?.discountType ?? 'amount',
      discountValue: existing?.discountValue ?? 0,
    );
  }

  void _changeQty(String key, double value) {
    final line = _cart[key];
    if (line == null) return;
    if (value <= 0) return setState(() => _cart.remove(key));
    if (!_hasStockFor(line.selection, value)) return;
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

  bool _hasStockFor(OrderProductSelection selection, double quantity) => quantity <= _availableFor(selection);

  double _availableFor(OrderProductSelection selection) => selection.effectiveStock;

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
          .map((l) => OrderItemInput(
                productId: l.selection.product.id,
                productVariantId: l.selection.variant?.id,
                quantity: l.quantity,
                discountType: l.discountType,
                discountValue: l.discountValue,
              ))
          .toList();
      final localSubtotal = _cart.values.fold<double>(0, (acc, l) => acc + l.netSubtotal);
      final localDiscount = localSubtotal * (((double.tryParse(_discountPercent.text) ?? 0).clamp(0, 100)) / 100);
      final saved = await context.read<OrdersCubit>().save(
            id: widget.orderId,
            clientId: _client!.id,
            items: items,
            discountTotal: subtotal * (((double.tryParse(_discountPercent.text) ?? 0).clamp(0, 100)) / 100),
            paymentTerms: _paymentTerms,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      final localTotal = localSubtotal - localDiscount;
      setState(() {
        _serverSubtotal = saved.subtotal;
        _serverDiscount = saved.discountTotal;
        _serverTotal = saved.total;
      });
      if ((saved.total - localTotal).abs() > 0.01 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El backend ajustó los totales por promociones/validaciones.')));
      }
      if (mounted) Navigator.pop(context, true);
    } on OrderException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo guardar el pedido.')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'compra_frecuente':
        return 'Compra frecuente';
      case 'hace_tiempo_no_compra':
        return 'Hace tiempo no compra';
      case 'mas_vendido_general':
        return 'Top general';
      case 'mas_vendido_zona':
        return 'Top zona';
      default:
        return 'Sugerido';
    }
  }
}

class _VariantQuickSheet extends StatefulWidget {
  const _VariantQuickSheet({required this.product, required this.variants});

  final OrderProductLookup product;
  final List<OrderProductVariantLookup> variants;

  @override
  State<_VariantQuickSheet> createState() => _VariantQuickSheetState();
}

class _VariantQuickSheetState extends State<_VariantQuickSheet> {
  late final Map<String, int> _quantities;

  @override
  void initState() {
    super.initState();
    _quantities = {for (final v in widget.variants) v.id: 0};
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Elegir variantes · ${widget.product.name}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...widget.variants.map((v) {
              final qty = _quantities[v.id] ?? 0;
              return ListTile(
                title: Text(v.name),
                subtitle: Text('Stock ${(v.effectiveStock ?? 0).toStringAsFixed(0)} · ${(v.effectivePrice ?? 0).toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(onPressed: qty > 0 ? () => setState(() => _quantities[v.id] = qty - 1) : null, icon: const Icon(Icons.remove)),
                    Text('$qty'),
                    IconButton(onPressed: qty < (v.effectiveStock ?? 0).toInt() ? () => setState(() => _quantities[v.id] = qty + 1) : null, icon: const Icon(Icons.add)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final selected = widget.variants
                      .where((v) => (_quantities[v.id] ?? 0) > 0)
                      .map((v) => OrderProductSelection(
                            product: widget.product,
                            variant: v,
                            initialQuantity: (_quantities[v.id] ?? 1).toDouble(),
                          ))
                      .toList();
                  Navigator.pop(context, selected);
                },
                child: const Text('Agregar seleccionadas'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLine {
  _CartLine({required this.key, required this.selection, required this.quantity, this.discountType = 'amount', this.discountValue = 0, double? originalUnitPrice, this.promoText = ''}) : originalUnitPrice = originalUnitPrice ?? selection.effectivePrice;

  final String key;
  final OrderProductSelection selection;
  final double quantity;
  final String discountType;
  final double discountValue;
  final double originalUnitPrice;
  final String promoText;

  String get displayName => selection.displayName;
  double get unitPrice => selection.effectivePrice;
  double get stock => selection.effectiveStock;
  bool get isValidStock => stock > 0 && quantity <= stock;
  bool get hasPromo => discountAmount > 0;

  double get discountAmount {
    if (discountType == 'percentage') return (unitPrice * quantity * discountValue) / 100;
    return discountValue;
  }

  double get netSubtotal => isValidStock ? (unitPrice * quantity - discountAmount).clamp(0, double.infinity) : 0;

  _CartLine copyWith({double? quantity, String? discountType, double? discountValue, double? originalUnitPrice, String? promoText}) => _CartLine(
        key: key,
        selection: selection,
        quantity: quantity ?? this.quantity,
        discountType: discountType ?? this.discountType,
        discountValue: discountValue ?? this.discountValue,
        originalUnitPrice: originalUnitPrice ?? this.originalUnitPrice,
        promoText: promoText ?? this.promoText,
      );
}
