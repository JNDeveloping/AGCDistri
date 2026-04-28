import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../pedidos/presentation/pages/order_detail_page.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../domain/models/delivery_model.dart';

class DeliveryDetailPage extends StatefulWidget {
  const DeliveryDetailPage({required this.deliveryId, super.key});

  final String deliveryId;

  @override
  State<DeliveryDetailPage> createState() => _DeliveryDetailPageState();
}

class _DeliveryDetailPageState extends State<DeliveryDetailPage> {
  late Future<DeliveryModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _reload();
  }

  Future<DeliveryModel> _reload() => context.read<DeliveryRepository>().getById(widget.deliveryId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoja de ruta')),
      body: FutureBuilder<DeliveryModel>(
        future: _future,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('No pudimos cargar la hoja de ruta.'));
          final delivery = snapshot.data!;

          return Column(
            children: [
              _DeliveryHeader(delivery: delivery, onOptimize: _optimize),
              Expanded(
                child: delivery.orders.isEmpty
                    ? const Center(child: Text('Este reparto todavía no tiene pedidos.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: delivery.orders.length,
                        itemBuilder: (_, i) => _orderCard(delivery.orders[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _orderCard(DeliveryOrderModel order) {
    final paymentLabel = order.paymentTerms == 'cuenta_corriente' ? 'Cuenta corriente' : 'Contado';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: _statusColor(order.status).withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Text('${order.visitOrder ?? '-'}')),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(order.clientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
                Chip(label: Text(_statusText(order.status))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Pedido #${order.orderNumber ?? '-'} · Total ${_money(order.total)}'),
            Text('${order.addressLine ?? '-'} ${order.city ?? ''}'.trim()),
            Text('Tel: ${order.clientPhone ?? '-'}'),
            Text('Pago: $paymentLabel · Saldo: ${_money(order.currentBalance ?? 0)}'),
            if ((order.notDeliveredReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Motivo no entregado: ${order.notDeliveredReason}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _openWhatsapp(order.clientPhone),
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('WhatsApp'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openMaps(order),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Ir'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openOrder(order),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Ver pedido'),
                ),
                FilledButton.icon(
                  onPressed: () => _markDelivered(order),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Entregado'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _markNotDelivered(order),
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('No entregado'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _markRescheduled(order),
                  icon: const Icon(Icons.event_repeat_rounded),
                  label: const Text('Reprogramar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markDelivered(DeliveryOrderModel order) async {
    bool collectedCash = false;
    double? collectedAmount;

    if (order.paymentTerms == 'contado') {
      final result = await _askCashCollection(order.total);
      if (result == null) return;
      collectedCash = result.$1;
      collectedAmount = result.$2;
    }

    await context.read<DeliveryRepository>().markDelivered(
          order.id,
          collectedCash: collectedCash,
          collectedAmount: collectedAmount,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido marcado como entregado.')));
    setState(() => _future = _reload());
  }

  Future<void> _markNotDelivered(DeliveryOrderModel order) async {
    final reason = await _askReason();
    if (reason == null || reason.trim().isEmpty) return;
    await context.read<DeliveryRepository>().markNotDelivered(order.id, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido marcado como no entregado.')));
    setState(() => _future = _reload());
  }

  Future<void> _markRescheduled(DeliveryOrderModel order) async {
    await context.read<DeliveryRepository>().markRescheduled(order.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido reprogramado para nuevo reparto.')));
    setState(() => _future = _reload());
  }

  Future<void> _optimize() async {
    Position? position;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          position = await Geolocator.getCurrentPosition();
        }
      }
    } catch (_) {}

    await context.read<DeliveryRepository>().optimizeRoute(
          widget.deliveryId,
          lat: position?.latitude,
          lng: position?.longitude,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recorrido optimizado y orden guardado.')));
    setState(() => _future = _reload());
  }

  Future<(bool, double?)?> _askCashCollection(double suggestedAmount) async {
    final controller = TextEditingController(text: suggestedAmount.toStringAsFixed(2));
    var collected = true;

    final result = await showDialog<(bool, double?)>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cobro contado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: collected,
                onChanged: (v) => setDialogState(() => collected = v),
                title: const Text('Pedido cobrado'),
              ),
              if (collected)
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monto cobrado'),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                (collected, collected ? (double.tryParse(controller.text.replaceAll(',', '.')) ?? suggestedAmount) : 0),
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    return result;
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo de no entrega (obligatorio)'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Ej: cliente ausente')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _openWhatsapp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final normalized = clean.startsWith('549') ? clean : '549$clean';
    final message = Uri.encodeComponent('Hola, estamos en camino con tu pedido.');
    final uri = Uri.parse('https://wa.me/$normalized?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps(DeliveryOrderModel order) async {
    Uri uri;
    if (order.latitude != null && order.longitude != null) {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${order.latitude},${order.longitude}');
    } else {
      final q = Uri.encodeComponent('${order.addressLine ?? ''} ${order.city ?? ''}');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$q');
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openOrder(DeliveryOrderModel order) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.orderId)));
    if (mounted) setState(() => _future = _reload());
  }

  String _statusText(String status) {
    switch (status) {
      case 'entregado':
        return 'Entregado';
      case 'no_entregado':
        return 'No entregado';
      case 'reprogramado':
        return 'Reprogramado';
      default:
        return 'Pendiente';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'entregado':
        return Colors.green;
      case 'no_entregado':
        return Colors.red;
      case 'reprogramado':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';
}

class _DeliveryHeader extends StatelessWidget {
  const _DeliveryHeader({required this.delivery, required this.onOptimize});

  final DeliveryModel delivery;
  final Future<void> Function() onOptimize;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reparto #${delivery.number} · ${delivery.zone ?? 'Sin zona'}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${delivery.totalOrders} pedidos · Total ${'\$${delivery.totalAmount.toStringAsFixed(2)}'}'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onOptimize,
              icon: const Icon(Icons.route_rounded),
              label: const Text('Optimizar recorrido'),
            ),
          ),
        ],
      ),
    );
  }
}
