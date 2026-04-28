import 'package:flutter/material.dart';

import '../../../pedidos/domain/models/order_model.dart';
import '../../data/repositories/credit_note_repository.dart';
import '../../domain/models/credit_note_model.dart';

class CreditNoteFormPage extends StatefulWidget {
  const CreditNoteFormPage({required this.order, required this.repository, super.key});

  final OrderModel order;
  final CreditNoteRepository repository;

  @override
  State<CreditNoteFormPage> createState() => _CreditNoteFormPageState();
}

class _CreditNoteFormPageState extends State<CreditNoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  late final List<_EditableItem> _items;
  bool _affectsStock = false;
  bool _affectsAccount = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = widget.order.items
        .map((item) => _EditableItem(
              item: item,
              qtyCtrl: TextEditingController(text: item.quantity.toStringAsFixed(0)),
              priceCtrl: TextEditingController(text: item.unitPrice.toStringAsFixed(2)),
            ))
        .toList();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    for (final item in _items) {
      item.qtyCtrl.dispose();
      item.priceCtrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva nota de crédito')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            TextFormField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(labelText: 'Motivo'),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingresá un motivo.' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _affectsStock,
              onChanged: (value) => setState(() => _affectsStock = value),
              title: const Text('Afecta stock'),
            ),
            SwitchListTile(
              value: _affectsAccount,
              onChanged: (value) => setState(() => _affectsAccount = value),
              title: const Text('Afecta cuenta corriente'),
            ),
            const SizedBox(height: 8),
            Text('Productos acreditados', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final editable in _items) _itemEditor(editable),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Guardando...' : 'Crear nota de crédito'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemEditor(_EditableItem editable) {
    final item = editable.item;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Vendido: ${item.quantity.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: editable.qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Cantidad a acreditar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: editable.priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Precio unitario'),
                  ),
                ),
              ],
            ),
            if (_affectsStock)
              CheckboxListTile(
                value: editable.returnToStock,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => editable.returnToStock = value ?? false),
                title: const Text('Devolver al stock'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final items = <CreditNoteItemInput>[];
    for (final editable in _items) {
      final qty = double.tryParse(editable.qtyCtrl.text.trim().replaceAll(',', '.')) ?? 0;
      if (qty <= 0) continue;
      final price = double.tryParse(editable.priceCtrl.text.trim().replaceAll(',', '.')) ?? 0;
      items.add(
        CreditNoteItemInput(
          productId: editable.item.productId,
          productNameSnapshot: editable.item.productName,
          quantity: qty,
          unitPrice: price,
          returnToStock: editable.returnToStock,
          reason: _reasonCtrl.text.trim(),
        ),
      );
    }

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleccioná al menos un producto con cantidad mayor a 0.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.repository.create(
        orderId: widget.order.id,
        reason: _reasonCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        affectsStock: _affectsStock,
        affectsAccount: _affectsAccount,
        items: items,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota de crédito creada correctamente.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EditableItem {
  _EditableItem({required this.item, required this.qtyCtrl, required this.priceCtrl});

  final OrderItemModel item;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;
  bool returnToStock = false;
}
