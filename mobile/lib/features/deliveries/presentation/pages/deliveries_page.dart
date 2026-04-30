import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../domain/models/delivery_model.dart';
import 'delivery_create_page.dart';
import 'delivery_detail_page.dart';

class DeliveriesPage extends StatefulWidget {
  const DeliveriesPage({super.key});

  static const path = '/repartos';
  static const name = 'repartos';

  @override
  State<DeliveriesPage> createState() => _DeliveriesPageState();
}

class _DeliveriesPageState extends State<DeliveriesPage> {
  late Future<List<DeliveryModel>> _future;
  String? _status;
  String _archived = 'active';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<DeliveryModel>> _load() {
    return context.read<DeliveryRepository>().list(status: _status, archived: _archived);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canManage = role == 'admin' || role == 'vendedor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repartos'),
        actions: [
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_alt_rounded),
            onSelected: (value) => setState(() {
              _status = value;
              _future = _load();
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Todos')),
              PopupMenuItem(value: 'pendiente', child: Text('Pendiente')),
              PopupMenuItem(value: 'en_reparto', child: Text('En reparto')),
              PopupMenuItem(value: 'finalizado', child: Text('Finalizado')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.archive_outlined),
            onSelected: (value) => setState(() {
              _archived = value;
              _future = _load();
            }),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'active', child: Text('Activos')),
              PopupMenuItem(value: 'archived', child: Text('Archivados')),
              PopupMenuItem(value: 'all', child: Text('Todos')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentRoute: DeliveriesPage.path, role: role),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _createDelivery(),
              icon: const Icon(Icons.add_road_rounded),
              label: const Text('Nuevo reparto'),
            )
          : null,
      body: FutureBuilder<List<DeliveryModel>>(
        future: _future,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('No se pudieron cargar repartos.'));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No hay repartos para mostrar.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('Reparto #${item.number} · ${_statusLabel(item.status)}'),
                  subtitle: Text('${item.date} · ${item.totalOrders} pedidos · ${_money(item.totalAmount)}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryDetailPage(deliveryId: item.id)));
                    if (mounted) {
                      setState(() {
                        _future = _load();
                      });
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _createDelivery() async {
    final id = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const DeliveryCreatePage()));
    if (!mounted || id == null) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DeliveryDetailPage(deliveryId: id)));
    if (mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  String _money(double value) => String.fromCharCode(36) + value.toStringAsFixed(2);

  String _statusLabel(String status) {
    switch (status) {
      case 'en_reparto':
        return 'En reparto';
      case 'finalizado':
        return 'Finalizado';
      case 'cancelado':
        return 'Cancelado';
      default:
        return 'Pendiente';
    }
  }
}
