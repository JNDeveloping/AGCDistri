import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../company_settings/presentation/cubit/company_settings_cubit.dart';
import '../../../credit_notes/data/repositories/credit_note_repository.dart';
import '../../../credit_notes/presentation/pages/order_credit_notes_page.dart';
import '../../../credit_notes/presentation/pages/credit_note_detail_page.dart';
import '../../../stock/presentation/pages/stock_product_detail_page.dart';
import '../../data/repositories/order_repository.dart';
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
  bool _validatingStock = false;
  OrderStockValidation? _stockValidation;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrdersCubit>().getById(widget.orderId);
    _refreshStockValidation();
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
                    if (o.hasCreditNotes) Text('Pedido con notas de crédito aplicadas', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Vendedor: ${o.sellerName}'),
                    Text('Saldo del cliente: disponible en Cuenta Corriente.'),
                    if ((o.notes ?? '').isNotEmpty) Text('Observaciones: ${o.notes}'),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              if (canManage) _actions(o, role),
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
                      _totalRow('Total original', o.total, strong: true),
                      _totalRow('Notas de crédito', -o.totalCredited),
                      _totalRow('Total neto', o.netTotal, strong: true),
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

  Widget _actions(OrderModel o, String role) {
    final canEditPending = o.status == 'pendiente';
    final canStatus = o.status != 'entregado' && o.status != 'cancelado';
    final blockedItem = _firstBlockedItem();
    final hasStockConflict = blockedItem != null || _validatingStock;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.icon(
          onPressed: () => _showPdf(o),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Ver PDF'),
        ),
        if (o.status == 'entregado')
          FilledButton.icon(
            onPressed: () => _sendPdfByWhatsApp(o),
            icon: const Icon(Icons.send_to_mobile_rounded),
            label: const Text('Enviar PDF por WhatsApp'),
          ),
        if (o.status == 'entregado')
          OutlinedButton.icon(
            onPressed: () async {
              final creditRepo = context.read<CreditNoteRepository>();
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderCreditNotesPage(order: o, repository: creditRepo),
                ),
              );
              if (mounted) {
                setState(() => _future = context.read<OrdersCubit>().getById(widget.orderId));
                await context.read<OrdersCubit>().load(forceRefresh: true);
              }
            },
            icon: const Icon(Icons.request_page_outlined),
            label: const Text('Notas de crédito'),
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
        if (canStatus)
          FilledButton.icon(
            onPressed: _changingStatus ? null : () => _openStatusSelector(o, role, hasStockConflict),
            icon: const Icon(Icons.sync_alt_rounded),
            label: Text(_changingStatus ? 'Actualizando...' : 'Cambiar estado'),
          ),
        if (_validatingStock)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 8),
                Text('Validando stock...'),
              ],
            ),
          ),
        if (blockedItem != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.45),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No hay stock suficiente para preparar este pedido.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text('Producto: ${blockedItem.productName}'),
                  Text('Disponible: ${blockedItem.availableStock.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
      ],
    );
  }


  List<String> _availableStatuses(String current) {
    switch (current) {
      case 'pendiente':
        return const ['preparado', 'cancelado'];
      case 'preparado':
        return const ['en_reparto', 'entregado', 'cancelado'];
      case 'en_reparto':
        return const ['entregado', 'cancelado'];
      default:
        return const [];
    }
  }

  Future<void> _openStatusSelector(OrderModel order, String role, bool hasStockConflict) async {
    final statuses = _availableStatuses(order.status);
    if (statuses.isEmpty) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: statuses
                .map((status) {
                  final disabled = _statusRequiresStock(status) && hasStockConflict;
                  final color = _statusColor(status);
                  return ActionChip(
                    backgroundColor: color.withValues(alpha: 0.16),
                    avatar: Icon(_statusIcon(status), color: color),
                    label: Text(_statusLabel(status)),
                    onPressed: disabled ? null : () => Navigator.pop(context, status),
                  );
                })
                .toList(),
          ),
        ),
      ),
    );

    if (selected == null) return;
    final requiresConfirm = selected == 'entregado' || selected == 'cancelado';
    if (requiresConfirm) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Confirmar cambio de estado'),
          content: Text('¿Deseás cambiar el estado a ${_statusLabel(selected)}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
          ],
        ),
      );
      if (ok != true) return;
    }

    await _changeStatus(order.id, selected, role);
  }

  Future<void> _changeStatus(String orderId, String status, String role) async {
    if (_statusRequiresStock(status)) {
      final blocked = _firstBlockedItem();
      if (blocked != null) {
        await _showInsufficientStockDialog(
          role: role,
          productId: blocked.productId,
          productName: blocked.productName,
          availableStock: blocked.availableStock,
        );
        return;
      }
    }

    await _runOrderAction(
      action: () => context.read<OrdersCubit>().changeStatus(orderId, status),
      successMessage: 'Estado actualizado.',
      role: role,
    );
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

  Future<void> _refreshOrderAndStockValidation() async {
    if (!mounted) return;
    setState(() => _future = context.read<OrdersCubit>().getById(widget.orderId));
    await _refreshStockValidation();
  }

  Future<void> _refreshStockValidation() async {
    if (!mounted) return;
    setState(() => _validatingStock = true);
    try {
      final validation = await context.read<OrdersCubit>().validateStock(widget.orderId);
      if (!mounted) return;
      setState(() => _stockValidation = validation);
    } catch (_) {
      if (!mounted) return;
      setState(() => _stockValidation = null);
    } finally {
      if (!mounted) return;
      setState(() => _validatingStock = false);
    }
  }

  Future<void> _runOrderAction({
    required Future<dynamic> Function() action,
    required String successMessage,
    required String role,
  }) async {
    setState(() => _changingStatus = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMessage)));
      await _refreshOrderAndStockValidation();
      await context.read<OrdersCubit>().load(forceRefresh: true);
    } on OrderException catch (error) {
      if (!mounted) return;
      if (error.isInsufficientStock) {
        await _showInsufficientStockDialog(
          role: role,
          productId: _resolveProductId(error.productName),
          productName: error.productName ?? 'Producto',
          availableStock: error.availableStock ?? 0,
        );
        await _refreshStockValidation();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo completar la acción. Intentá nuevamente.')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _changingStatus = false);
    }
  }

  bool _statusRequiresStock(String status) => status == 'preparado';

  String? _resolveProductId(String? productName) {
    if (productName == null) return null;
    final order = _stockValidation;
    if (order == null) return null;
    for (final item in order.items) {
      if (item.productName == productName) return item.productId;
    }
    return null;
  }

  OrderStockValidationItem? _firstBlockedItem() {
    final items = _stockValidation?.items ?? const <OrderStockValidationItem>[];
    for (final item in items) {
      if (!item.hasStock) return item;
    }
    return null;
  }

  Future<void> _showInsufficientStockDialog({
    required String role,
    required String productName,
    required double availableStock,
    String? productId,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final isAdmin = role == 'admin';
        return AlertDialog(
          title: const Text('Stock insuficiente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No hay stock suficiente para preparar este pedido.'),
              const SizedBox(height: 8),
              Text('Producto: $productName'),
              Text('Disponible: ${availableStock.toStringAsFixed(0)}'),
            ],
          ),
          actions: [
            if (isAdmin && productId != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StockProductDetailPage(productId: productId)),
                  );
                },
                child: const Text('Ver producto'),
              ),
            if (isAdmin && productId != null)
              FilledButton.tonal(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => StockProductDetailPage(productId: productId)),
                  );
                },
                child: const Text('Ajustar stock'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Volver al pedido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPdf(OrderModel order) async {
    final doc = await _buildPdf(order);
    await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'pedido_${order.orderNumber}.pdf');
  }

  Future<pw.Document> _buildPdf(OrderModel order) async {
    final settings = context.read<CompanySettingsCubit>().state.settings;
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (_) => [
          pw.Text('Remito / Pedido #${order.orderNumber}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Empresa: ${settings.companyName}'),
          pw.Text('CUIT: ${settings.taxId ?? '-'}  | Dirección: ${settings.address ?? '-'}'),
          pw.Text('Tel: ${settings.phone ?? '-'}  | Email: ${settings.email ?? '-'}'),
          pw.Divider(),
          pw.Text('Cliente: ${order.clientName}'),
          pw.Text('Teléfono cliente: ${order.clientPhone ?? '-'}'),
          pw.Text('Dirección cliente: ${order.deliveryAddress ?? '-'}'),
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
    return doc;
  }

  Future<void> _sendPdfByWhatsApp(OrderModel order) async {
    final cleaned = _cleanPhone(order.clientPhone);
    if (cleaned == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El cliente no tiene teléfono/WhatsApp configurado.')),
      );
      return;
    }

    final whatsappPhone = cleaned.startsWith('549') ? cleaned : '549$cleaned';
    final message = 'Hola, te enviamos el comprobante del pedido Nº ${order.orderNumber}';

    try {
      final doc = await _buildPdf(order);
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/pedido_${order.orderNumber}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await doc.save(), flush: true);

      final whatsappUrl = Uri.parse('https://wa.me/$whatsappPhone?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }

      await Share.shareXFiles([XFile(filePath)], text: message, subject: 'Comprobante pedido #${order.orderNumber}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el PDF por WhatsApp.')),
      );
    }
  }

  String? _cleanPhone(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length < 8) return null;
    return digits;
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 18, color: color),
          const SizedBox(width: 6),
          Text(_statusLabel(status), style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pendiente':
        return 'Pendiente';
      case 'preparado':
        return 'Preparado';
      case 'en_reparto':
        return 'En reparto';
      case 'entregado':
        return 'Entregado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pendiente':
        return Colors.amber.shade800;
      case 'preparado':
        return Colors.deepPurple;
      case 'en_reparto':
        return Colors.indigo;
      case 'entregado':
        return Colors.green.shade700;
      case 'cancelado':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pendiente':
        return Icons.timelapse_rounded;
      case 'preparado':
        return Icons.inventory_2_rounded;
      case 'en_reparto':
        return Icons.local_shipping_rounded;
      case 'entregado':
        return Icons.check_circle_rounded;
      case 'cancelado':
        return Icons.cancel_rounded;
      default:
        return Icons.info_outline;
    }
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
