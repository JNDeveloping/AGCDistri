import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../productos/presentation/pages/barcode_scanner_page.dart';
import '../../data/repositories/stock_repository.dart';

class StockQuickEntryPage extends StatefulWidget {
  const StockQuickEntryPage({super.key});

  @override
  State<StockQuickEntryPage> createState() => _StockQuickEntryPageState();
}

class _StockQuickEntryPageState extends State<StockQuickEntryPage> {
  final _barcode = TextEditingController();
  final _qty = TextEditingController(text: '1');
  bool _saving = false;
  StockLookupItem? _selected;

  StockRepository get _repo => context.read<StockRepository>();

  @override
  void dispose() {
    _barcode.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingreso rápido de mercadería')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _barcode,
            decoration: InputDecoration(
              labelText: 'Código de barras / interno',
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner_rounded),
                onPressed: _scan,
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _search, icon: const Icon(Icons.search_rounded), label: const Text('Buscar')),
          const SizedBox(height: 14),
          if (_selected != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selected!.displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Stock actual: ${_selected!.effectiveStock.toStringAsFixed(0)}'),
                    Text('Precio: ${_selected!.effectivePrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _qty,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cantidad a ingresar'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saving ? null : _confirm,
              icon: const Icon(Icons.add_box_rounded),
              label: Text(_saving ? 'Guardando...' : 'Confirmar ingreso'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const BarcodeScannerPage()));
    if (code == null || code.trim().isEmpty) return;
    _barcode.text = code.trim();
    await _search();
  }

  Future<void> _search() async {
    final term = _barcode.text.trim();
    if (term.isEmpty) return;
    try {
      final items = await _repo.lookupByCode(term);
      if (!mounted) return;
      if (items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se encontró producto/variante.')));
        return;
      }
      setState(() => _selected = items.first);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirm() async {
    if (_selected == null) return;
    final qty = double.tryParse(_qty.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá una cantidad válida.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await _repo.createMovement(
        productId: _selected!.productId,
        productVariantId: _selected!.variantId,
        quantity: qty,
        movementType: 'entrada',
        reason: 'Ingreso rápido de mercadería',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingreso aplicado correctamente.')));
      setState(() {
        _selected = null;
        _barcode.clear();
        _qty.text = '1';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
