import 'package:flutter/material.dart';

import '../../data/repositories/promotion_repository.dart';
import '../../domain/models/promotion_model.dart';

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

  static const _promoTypes = {
    'quantity_discount': 'Descuento por unidades',
    'bulk_discount': 'Descuento por bultos',
    'tiered_discount': 'Descuento escalonado',
    'combo': 'Combo',
    'x_for_y': 'Llevá X pagá Y',
    'order_total_discount': 'Descuento por monto total',
    'target_discount': 'Descuento por cliente/zona',
    'stock_discount': 'Liquidación por stock',
  };
  static const _discountTypes = {
    'percentage': 'Porcentaje',
    'fixed_amount': 'Monto fijo',
    'fixed_price': 'Precio especial',
  };

  String _type = 'quantity_discount';
  String _discType = 'percentage';
  bool _stack = false;
  bool _active = true;
  bool _saving = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadIfEditing();
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _priority.dispose();
    _minQty.dispose();
    _discValue.dispose();
    super.dispose();
  }

  Future<void> _loadIfEditing() async {
    if (widget.promotionId == null) return;
    setState(() => _loading = true);
    try {
      final promotion = await widget.repository.getById(widget.promotionId!);
      _applyPromotion(promotion);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo cargar: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyPromotion(PromotionModel promotion) {
    _name.text = promotion.name;
    _desc.text = promotion.description ?? '';
    _priority.text = '${promotion.priority}';
    _type = promotion.type;
    _active = promotion.isActive;
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
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
                    items: _promoTypes.entries
                        .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? _type),
                  ),
                  SwitchListTile(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    title: const Text('Activa'),
                  ),
                  SwitchListTile(
                    value: _stack,
                    onChanged: (v) => setState(() => _stack = v),
                    title: const Text('Combinable'),
                  ),
                  TextFormField(controller: _priority, decoration: const InputDecoration(labelText: 'Prioridad')),
                  TextFormField(controller: _minQty, decoration: const InputDecoration(labelText: 'Cantidad mínima')),
                  DropdownButtonFormField<String>(
                    value: _discType,
                    decoration: const InputDecoration(labelText: 'Tipo de descuento'),
                    items: _discountTypes.entries
                        .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _discType = v ?? _discType),
                  ),
                  TextFormField(controller: _discValue, decoration: const InputDecoration(labelText: 'Valor descuento')),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Guardando...' : 'Guardar'),
                  ),
                ],
              ),
            ),
    );
  }
}
