import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../deliveries/presentation/pages/delivery_create_page.dart';
import '../../../pedidos/data/repositories/order_repository.dart';
import '../../../pedidos/domain/models/order_model.dart';
import '../../../pedidos/presentation/pages/pedidos_page.dart';
import '../../data/repositories/client_repository.dart';
import '../../domain/models/client_model.dart';
import '../cubit/clients_cubit.dart';

class ZoneDetailPage extends StatefulWidget {
  const ZoneDetailPage({required this.zone, super.key});

  final ClientZone zone;

  @override
  State<ZoneDetailPage> createState() => _ZoneDetailPageState();
}

class _ZoneDetailPageState extends State<ZoneDetailPage> {
  bool _loading = true;
  ZoneSummary? _summary;
  List<ClientModel> _clients = const [];
  List<OrderModel> _orders = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        context.read<ClientsCubit>().getZoneSummary(widget.zone.id),
        context.read<ClientRepository>().list(query: '', zoneId: widget.zone.id, page: 1),
        context.read<OrderRepository>().list(zoneId: widget.zone.id, limit: 20),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as ZoneSummary;
        _clients = (results[1] as ClientListResponse).items;
        _orders = (results[2] as OrdersListResult).items;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Zona: ${widget.zone.name}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Métricas básicas', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Text('Clientes: ${_summary?.totalClients ?? 0}'),
                          Text('Pedidos: ${_summary?.totalOrders ?? 0}'),
                          Text('Pendientes: ${_summary?.pendingOrders ?? 0}'),
                          Text('Preparados: ${_summary?.preparedOrders ?? 0}'),
                          Text('Entregados: ${_summary?.deliveredOrders ?? 0}'),
                          Text('Ventas: \$${(_summary?.totalSales ?? 0).toStringAsFixed(2)}'),
                          Text('Deuda: \$${(_summary?.totalDebt ?? 0).toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilledButton.tonal(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PedidosPage(initialZoneId: widget.zone.id)));
                        },
                        child: const Text('Ver pedidos de esta zona'),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryCreatePage(initialZoneId: widget.zone.id)));
                        },
                        child: const Text('Crear reparto para esta zona'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Clientes de esta zona', style: TextStyle(fontWeight: FontWeight.w700)),
                  ..._clients.take(8).map((c) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.businessName),
                        subtitle: Text(c.phone),
                      )),
                  const Divider(),
                  const Text('Pedidos de esta zona', style: TextStyle(fontWeight: FontWeight.w700)),
                  ..._orders.take(8).map((o) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Pedido #${o.orderNumber} · ${o.clientName}'),
                        subtitle: Text('${o.status} · \$${o.total.toStringAsFixed(2)}'),
                      )),
                ],
              ),
            ),
    );
  }
}
