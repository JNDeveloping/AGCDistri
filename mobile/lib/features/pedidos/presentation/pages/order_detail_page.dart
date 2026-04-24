import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/order_model.dart';
import '../cubit/orders_cubit.dart';
import 'order_form_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<OrderModel> _future;
  bool _changingStatus = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrdersCubit>().getById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canManage = role == 'admin' || role == 'vendedor';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de pedido')),
      body: FutureBuilder<OrderModel>(
        future: _future,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text('No se pudo cargar el pedido.'));
          final o = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(
                      children: [
                        Expanded(child: Text('Pedido #${o.orderNumber}', style: Theme.of(context).textTheme.titleLarge)),
                        _statusBadge(o.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Cliente: ${o.clientName}'),
                    Text('Fecha: ${o.orderDate?.toLocal().toString().split('.').first ?? '-'}'),
                    Text('Condición de pago: ${o.paymentTerms ?? '-'}'),
                    Text('Vendedor: ${o.sellerName}'),
                    Text('Saldo del cliente: disponible en Cuenta Corriente.'),
                    if ((o.notes ?? '').isNotEmpty) Text('Observaciones: ${o.notes}'),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              if (canManage) _actions(o),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      for (final i in o.items)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(i.productName),
                          subtitle: Text('Cant: ${i.quantity} · Unit: ${i.unitPrice.toStringAsFixed(2)} · Desc: ${i.discountType == 'percentage' ? '${i.discountValue.toStringAsFixed(2)}%' : i.discountValue.toStringAsFixed(2)}'),
                          trailing: Text(i.subtotal.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      const Divider(),
                      _totalRow('Subtotal', o.subtotal),
                      _totalRow('Descuento general', o.discountTotal),
                      _totalRow('Total', o.total, strong: true),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _actions(OrderModel o) {
    final canEditPending = o.status == 'pendiente';
    final canStatus = o.status != 'entregado' && o.status != 'cancelado';

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _showPdf(o),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Ver PDF'),
        ),
        if (canEditPending)
          OutlinedButton.icon(
            onPressed: () async {
              final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => OrderFormPage(orderId: o.id)));
              if (changed == true && mounted) setState(() => _future = context.read<OrdersCubit>().getById(widget.orderId));
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        if (canEditPending)
          OutlinedButton.icon(
            onPressed: () => _confirmDelete(o),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar'),
          ),
        if (o.status != 'cancelado')
          TextButton.icon(
            onPressed: () async {
              await context.read<OrdersCubit>().cancel(o.id);
              if (mounted) setState(() => _future = context.read<OrdersCubit>().getById(widget.orderId));
            },
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar pedido'),
          ),
        if (canStatus)
          for (final status in const ['confirmado', 'preparado', 'en_reparto', 'entregado'])
            FilledButton.tonal(
              onPressed: _changingStatus ? null : () => _changeStatus(o.id, status),
              child: Text(_changingStatus ? 'Actualizando...' : status),
            ),
      ],
    );
  }

  Future<void> _changeStatus(String orderId, String status) async {
    setState(() => _changingStatus = true);
    try {
      await context.read<OrdersCubit>().changeStatus(orderId, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Estado actualizado.')));
        setState(() => _future = context.read<OrdersCubit>().getById(widget.orderId));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _changingStatus = false);
    }
  }

  Future<void> _confirmDelete(OrderModel order) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar pedido'),
        content: const Text('Se eliminará solo si no tiene movimientos asociados. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await context.read<OrdersCubit>().delete(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido eliminado correctamente.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _showPdf(OrderModel order) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (_) => [
          pw.Text('Remito / Pedido #${order.orderNumber}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Empresa: AGC Distribuidora'),
          pw.Text('CUIT: -  | Dirección: -  | Tel: -  | Email: -'),
          pw.Divider(),
          pw.Text('Cliente: ${order.clientName}'),
          pw.Text('Fecha: ${order.orderDate?.toLocal().toString().split('.').first ?? '-'}'),
          pw.Text('Estado: ${order.status}'),
          pw.Text('Condición de pago: ${order.paymentTerms ?? '-'}'),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headers: const ['Producto', 'Cant', 'Unit', 'Desc', 'Subtotal'],
            data: order.items
                .map((i) => [
                      i.productName,
                      i.quantity.toStringAsFixed(0),
                      i.unitPrice.toStringAsFixed(2),
                      i.discountType == 'percentage' ? '${i.discountValue.toStringAsFixed(2)}%' : i.discountValue.toStringAsFixed(2),
                      i.subtotal.toStringAsFixed(2),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Subtotal: ${order.subtotal.toStringAsFixed(2)}')),
          pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Descuento general: ${order.discountTotal.toStringAsFixed(2)}')),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('TOTAL: ${order.total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          if ((order.notes ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Observaciones: ${order.notes}'),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'pedido_${order.orderNumber}.pdf');
  }

  Widget _statusBadge(String status) {
    final color = switch (status) {
      'pendiente' => Colors.amber,
      'confirmado' => Colors.blue,
      'preparado' => Colors.deepPurple,
      'en_reparto' => Colors.indigo,
      'entregado' => Colors.green,
      _ => Colors.red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _totalRow(String label, double value, {bool strong = false}) {
    final style = TextStyle(fontWeight: strong ? FontWeight.w800 : FontWeight.w500, fontSize: strong ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value.toStringAsFixed(2), style: style),
        ],
      ),
    );
  }
}
