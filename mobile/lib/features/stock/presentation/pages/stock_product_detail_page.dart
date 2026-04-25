import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/stock_repository.dart';
import '../../domain/models/stock_models.dart';

class StockProductDetailPage extends StatefulWidget {
  const StockProductDetailPage({required this.productId, super.key});
  final String productId;

  @override
  State<StockProductDetailPage> createState() => _StockProductDetailPageState();
}

class _StockProductDetailPageState extends State<StockProductDetailPage> {
  StockItem? _item;
  List<StockMovement> _movements = [];
  bool _loading = true;

  StockRepository get _repo => context.read<StockRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _repo.detail(widget.productId);
      final m = await _repo.movements(widget.productId);
      if (mounted) setState(() {
        _item = d;
        _movements = m.take(20).toList();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canAdjust = role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de stock')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _item == null
              ? const Center(child: Text('No se pudo cargar el producto'))
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_item!.name, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('Stock actual', style: Theme.of(context).textTheme.labelLarge),
                          Text(_item!.stockCurrent.toStringAsFixed(2), style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                          Text('Stock mínimo: ${_item!.stockMinimum.toStringAsFixed(2)}'),
                          if (canAdjust) ...[
                            const SizedBox(height: 10),
                            FilledButton.icon(onPressed: _openAdjust, icon: const Icon(Icons.tune), label: const Text('Ajustar stock')),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Últimos movimientos', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_movements.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Sin movimientos registrados.'))),
                    ..._movements.map((m) => Card(
                          child: ListTile(
                            title: Text('${m.movementType} · ${m.quantity.toStringAsFixed(2)}'),
                            subtitle: Text('${m.reason}\n${m.createdAt?.toLocal().toString().split('.').first ?? '-'} · ${m.userName ?? '-'}'),
                            isThreeLine: true,
                            trailing: Text('${m.previousStock.toStringAsFixed(2)} → ${m.newStock.toStringAsFixed(2)}'),
                          ),
                        )),
                  ],
                ),
    );
  }

  Future<void> _openAdjust() async {
    final type = ValueNotifier<String>('ajuste');
    final qty = TextEditingController();
    final reason = TextEditingController();
    final notes = TextEditingController();
    final isAbsolute = ValueNotifier<bool>(true);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ValueListenableBuilder<String>(
            valueListenable: type,
            builder: (_, v, __) => DropdownButtonFormField<String>(
              value: v,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                DropdownMenuItem(value: 'salida', child: Text('Salida')),
                DropdownMenuItem(value: 'ajuste', child: Text('Ajuste')),
                DropdownMenuItem(value: 'devolucion', child: Text('Devolución')),
                DropdownMenuItem(value: 'merma', child: Text('Merma')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
              ],
              onChanged: (nv) => type.value = nv ?? 'ajuste',
              decoration: const InputDecoration(labelText: 'Tipo de movimiento'),
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<bool>(
            valueListenable: isAbsolute,
            builder: (_, abs, __) => SwitchListTile(
              value: abs,
              onChanged: (v) => isAbsolute.value = v,
              title: Text(abs ? 'Stock final absoluto' : 'Cantidad a mover'),
            ),
          ),
          TextField(controller: qty, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: isAbsolute.value ? 'Nuevo stock' : 'Cantidad')),
          TextField(controller: reason, decoration: const InputDecoration(labelText: 'Motivo (obligatorio)')),
          TextField(controller: notes, decoration: const InputDecoration(labelText: 'Observaciones (opcional)')),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ]),
      ),
    );

    if (ok == true && _item != null) {
      final val = double.tryParse(qty.text) ?? -1;
      if (reason.text.trim().isEmpty || val < 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completar datos válidos.')));
        return;
      }
      try {
        if (isAbsolute.value) {
          await _repo.adjust(productId: _item!.productId, newStock: val, reason: reason.text.trim(), notes: notes.text.trim().isEmpty ? null : notes.text.trim());
        } else {
          final current = _item!.stockCurrent;
          final next = type.value == 'salida' || type.value == 'merma' || type.value == 'transferencia' ? current - val : current + val;
          await _repo.adjust(productId: _item!.productId, newStock: next, reason: reason.text.trim(), notes: notes.text.trim().isEmpty ? null : notes.text.trim());
        }
        await _load();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}
