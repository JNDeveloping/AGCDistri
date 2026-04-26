import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/repositories/delivery_repository.dart';
import '../../domain/models/delivery_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
          if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));

          final delivery = snapshot.data!;
          final markers = delivery.orders
              .where((o) => o.latitude != null && o.longitude != null)
              .map(
                (o) => Marker(
                  width: 46,
                  height: 46,
                  point: LatLng(o.latitude!, o.longitude!),
                  child: CircleAvatar(
                    backgroundColor: _statusColor(o.status),
                    child: Text('${o.visitOrder ?? '-'}'),
                  ),
                ),
              )
              .toList();

          return Column(
            children: [
              if (markers.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: FlutterMap(
                    options: MapOptions(initialCenter: markers.first.point, initialZoom: 12),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.agc.distribuidora',
                      ),
                      MarkerLayer(markers: markers),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _optimize,
                        icon: const Icon(Icons.route_rounded),
                        label: const Text('Optimizar recorrido'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: delivery.orders.length,
                  itemBuilder: (_, i) {
                    final order = delivery.orders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text('${order.addressLine ?? '-'} · ${order.city ?? ''}'),
                            Text('Tel: ${order.clientPhone ?? '-'}'),
                            Text('Total: \$${order.total.toStringAsFixed(2)} · ${order.paymentTerms ?? '-'}'),
                            Text('Saldo: \$${(order.currentBalance ?? 0).toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openWhatsapp(order.clientPhone),
                                  icon: const Icon(Icons.chat),
                                  label: const Text('WhatsApp'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _openMaps(order),
                                  icon: const Icon(Icons.navigation_rounded),
                                  label: const Text('Ir'),
                                ),
                                FilledButton.icon(
                                  onPressed: () => _markOrder(order, 'entregado'),
                                  icon: const Icon(Icons.check_circle_rounded),
                                  label: const Text('Entregado'),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () => _markOrder(order, 'no_entregado'),
                                  icon: const Icon(Icons.cancel_rounded),
                                  label: const Text('No entregado'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markOrder(DeliveryOrderModel order, String status) async {
    String? reason;
    if (status == 'no_entregado') {
      reason = await _askReason();
      if (reason == null || reason.trim().isEmpty) return;
    }

    await context.read<DeliveryRepository>().updateOrderStatus(
          order.id,
          status: status,
          reason: reason,
          collectedCash: status == 'entregado' && order.paymentTerms == 'contado',
          collectedAmount: status == 'entregado' && order.paymentTerms == 'contado' ? order.total : 0,
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Entrega marcada: $status')));
    setState(() => _future = _reload());
  }

  Future<void> _optimize() async {
    Position? position;
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recorrido optimizado.')));
    setState(() => _future = _reload());
  }

  Future<String?> _askReason() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Motivo de no entrega'),
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
    final uri = Uri.parse('https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}');
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

  Color _statusColor(String status) {
    switch (status) {
      case 'entregado':
        return Colors.green;
      case 'no_entregado':
        return Colors.red;
      case 'reprogramado':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}
