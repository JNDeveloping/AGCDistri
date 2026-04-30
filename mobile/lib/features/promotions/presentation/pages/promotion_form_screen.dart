import 'package:flutter/material.dart';

import '../../data/repositories/promotion_repository.dart';

class PromotionFormScreen extends StatefulWidget {
  const PromotionFormScreen({required this.repository, this.promotionId, super.key});

  final PromotionRepository repository;
  final String? promotionId;

  @override
  State<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends State<PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _priority = TextEditingController(text: '0');
  final _minQty = TextEditingController();
  final _discValue = TextEditingController(text: '0');

  static const _promoTypes = [
    'quantity_discount',
    'bulk_discount',
    'tiered_discount',
    'combo',
    'x_for_y',
    'order_total_discount',
    'target_discount',
    'stock_discount',
  ];
  static const _discountTypes = ['percentage', 'fixed_amount', 'fixed_price'];

  String _type = 'quantity_discount';
  String _discType = 'percentage';
  bool _stack = false;
  bool _active = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _priority.dispose();
    _minQty.dispose();
    _discValue.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'type': _type,
      'priority': int.tryParse(_priority.text) ?? 0,
      'stackable': _stack,
      'isActive': _active,
      'minQuantity': double.tryParse(_minQty.text),
      'discountType': _discType,
      'discountValue': double.tryParse(_discValue.text),
    }..removeWhere((k, v) => v == null || v == '');

    try {
      await widget.repository.save(body, id: widget.promotionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promoción guardada')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.promotionId == null ? 'Nueva promoción' : 'Editar promoción')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            TextFormField(controller: _desc, decoration: const InputDecoration(labelText: 'Descripción')),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Tipo de promoción'),
              items: _promoTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            SwitchListTile(value: _active, onChanged: (v) => setState(() => _active = v), title: const Text('Activa')),
            SwitchListTile(value: _stack, onChanged: (v) => setState(() => _stack = v), title: const Text('Combinable')),
            TextFormField(controller: _priority, decoration: const InputDecoration(labelText: 'Prioridad')),
            TextFormField(controller: _minQty, decoration: const InputDecoration(labelText: 'Cantidad mínima')),
            DropdownButtonFormField<String>(
              value: _discType,
              decoration: const InputDecoration(labelText: 'Tipo de descuento'),
              items: _discountTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _discType = v ?? _discType),
            ),
            TextFormField(controller: _discValue, decoration: const InputDecoration(labelText: 'Valor descuento')),
            const SizedBox(height: 16),
            FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Guardando...' : 'Guardar')),
          ],
        ),
      ),
    );
  }
}
