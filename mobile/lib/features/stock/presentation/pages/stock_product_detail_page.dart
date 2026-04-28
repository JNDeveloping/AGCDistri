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
      if (mounted) {
        setState(() {
          _item = d;
          _movements = m.take(20).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No se pudo cargar el producto'),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primaryContainer,
                                Theme.of(context).colorScheme.secondaryContainer,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_item!.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 10),
                              Text('Stock actual', style: Theme.of(context).textTheme.labelLarge),
                              Text(
                                _item!.stockCurrent.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1),
                              ),
                              Text('Stock mínimo: ${_item!.stockMinimum.toStringAsFixed(2)}'),
                              if (_item!.hasVariants && _item!.variants.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _item!.variants
                                      .where((v) => v.isActive)
                                      .map((v) => Chip(label: Text('${v.name}: ${(v.stock ?? _item!.stockCurrent).toStringAsFixed(2)}')))
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: 8),
                              if (canAdjust)
                                FilledButton.icon(
                                  onPressed: _openAdjust,
                                  icon: const Icon(Icons.tune),
                                  label: const Text('Ajustar stock'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Últimos movimientos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_movements.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Sin movimientos registrados.'),
                          ),
                        ),
                      ..._movements.map(
                        (m) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _movementColor(m.movementType).withValues(alpha: 0.16),
                              child: Icon(Icons.swap_horiz_rounded, color: _movementColor(m.movementType)),
                            ),
                            title: Text('${_labelMovement(m.movementType)} · ${m.quantity.toStringAsFixed(2)}'),
                            subtitle: Text(
                              '${m.reason}\n${_formatDateTime(m.createdAt)} · ${m.userName ?? '-'}',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              '${m.previousStock.toStringAsFixed(2)} → ${m.newStock.toStringAsFixed(2)}',
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _openAdjust() async {
    final type = ValueNotifier<String>('ajuste');
    final qty = TextEditingController();
    final reason = TextEditingController();
    final notes = TextEditingController();
    final isAbsolute = ValueNotifier<bool>(true);
    final selectedVariantId = ValueNotifier<String?>(null);

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_item!.hasVariants && _item!.variants.isNotEmpty)
              ValueListenableBuilder<String?>(
                valueListenable: selectedVariantId,
                builder: (_, selected, __) => DropdownButtonFormField<String?>(
                  value: selected,
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Stock general del producto')),
                    ..._item!.variants
                        .where((v) => v.isActive)
                        .map((v) => DropdownMenuItem<String?>(value: v.id, child: Text('${v.name} · Stock ${(v.stock ?? 0).toStringAsFixed(2)}'))),
                  ],
                  onChanged: (value) => selectedVariantId.value = value,
                  decoration: const InputDecoration(labelText: 'Variante a ajustar'),
                ),
              ),
            const SizedBox(height: 8),
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
                title: Text(abs ? 'Ingresar stock final absoluto' : 'Ingresar cantidad a mover'),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: isAbsolute,
              builder: (_, abs, __) => TextField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: abs ? 'Nuevo stock' : 'Cantidad'),
              ),
            ),
            TextField(controller: reason, decoration: const InputDecoration(labelText: 'Motivo (obligatorio)')),
            TextField(controller: notes, decoration: const InputDecoration(labelText: 'Observaciones (opcional)')),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );

    if (ok == true && _item != null) {
      final val = double.tryParse(qty.text) ?? -1;
      if (reason.text.trim().isEmpty || val < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completá datos válidos.')));
        }
        return;
      }

      try {
        final selectedVariant = _item!.variants.where((v) => v.id == selectedVariantId.value).toList();
        final currentVariant = selectedVariant.isEmpty ? null : selectedVariant.first;
        if (isAbsolute.value) {
          await _repo.adjust(
            productId: _item!.productId,
            productVariantId: selectedVariantId.value,
            newStock: val,
            reason: reason.text.trim(),
            notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
          );
        } else {
          final current = currentVariant == null ? _item!.stockCurrent : (currentVariant.stock ?? _item!.stockCurrent);
          final goesOut = type.value == 'salida' || type.value == 'merma' || type.value == 'transferencia';
          final next = goesOut ? current - val : current + val;
          await _repo.adjust(
            productId: _item!.productId,
            productVariantId: selectedVariantId.value,
            newStock: next,
            reason: reason.text.trim(),
            notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajuste de stock aplicado.')));
        }
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$min';
  }

  String _labelMovement(String raw) {
    switch (raw) {
      case 'entrada':
        return 'Entrada';
      case 'salida':
        return 'Salida';
      case 'devolucion':
        return 'Devolución';
      case 'merma':
        return 'Merma';
      case 'transferencia':
        return 'Transferencia';
      case 'ajuste':
        return 'Ajuste';
      default:
        return raw;
    }
  }

  Color _movementColor(String movementType) {
    if (movementType == 'salida' || movementType == 'merma') return Colors.red.shade700;
    if (movementType == 'entrada' || movementType == 'devolucion') return Colors.green.shade700;
    if (movementType == 'transferencia') return Colors.blue.shade700;
    return Colors.amber.shade800;
  }
}
