import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../users/data/repositories/users_repository.dart';
import '../../../users/domain/models/app_user.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../domain/models/delivery_model.dart';

class DeliveryCreatePage extends StatefulWidget {
  const DeliveryCreatePage({this.initialZoneId, super.key});

  final String? initialZoneId;

  @override
  State<DeliveryCreatePage> createState() => _DeliveryCreatePageState();
}

class _DeliveryCreatePageState extends State<DeliveryCreatePage> {
  int _step = 0;
  bool _loading = true;
  bool _saving = false;

  List<DeliveryZoneModel> _zones = [];
  List<DeliveryOrderModel> _pendingOrders = [];
  List<AppUser> _drivers = [];

  String? _zoneId;
  String? _driverId;
  final Set<String> _selectedOrderIds = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _loading = true);
    try {
      final zones = await context.read<DeliveryRepository>().listZones();
      final users = await context.read<UsersRepository>().list();
      if (!mounted) return;
      setState(() {
        _zones = zones;
        _drivers = users.where((u) => u.isActive && u.role == 'repartidor').toList();
        if (widget.initialZoneId != null && _zones.any((z) => z.id == widget.initialZoneId)) {
          _zoneId = widget.initialZoneId;
        }
      });
    } catch (_) {
      _msg('No pudimos cargar zonas o repartidores. Reintentá.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadPendingOrders() async {
    if (_zoneId == null) return;
    setState(() => _loading = true);
    try {
      final rows = await context.read<DeliveryRepository>().listPendingOrders(_zoneId!);
      if (!mounted) return;
      setState(() {
        _pendingOrders = rows;
        _selectedOrderIds.clear();
      });
    } catch (_) {
      _msg('No se pudieron obtener pedidos de la zona seleccionada.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedOrders = _pendingOrders.where((o) => _selectedOrderIds.contains(o.orderId)).toList();
    final totalToCollect = selectedOrders.fold<double>(0, (acc, o) => acc + o.total);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo reparto por zona')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              currentStep: _step,
              controlsBuilder: (context, details) {
                final isLast = _step == 3;
                return Row(
                  children: [
                    FilledButton(
                      onPressed: _saving ? null : details.onStepContinue,
                      child: Text(isLast ? 'Crear reparto' : 'Continuar'),
                    ),
                    const SizedBox(width: 12),
                    if (_step > 0)
                      OutlinedButton(
                        onPressed: _saving ? null : details.onStepCancel,
                        child: const Text('Atrás'),
                      ),
                  ],
                );
              },
              onStepCancel: () => setState(() => _step -= 1),
              onStepContinue: () async {
                if (_step == 0) {
                  if (_zoneId == null) return _msg('Seleccioná una zona/ruta.');
                  await _loadPendingOrders();
                  setState(() => _step = 1);
                  return;
                }
                if (_step == 1) {
                  if (_selectedOrderIds.isEmpty) return _msg('Seleccioná al menos un pedido.');
                  setState(() => _step = 2);
                  return;
                }
                if (_step == 2) {
                  if (_driverId == null) return _msg('Seleccioná un repartidor.');
                  setState(() => _step = 3);
                  return;
                }
                await _create();
              },
              steps: [
                Step(
                  isActive: _step >= 0,
                  title: const Text('Zona / Ruta'),
                  content: DropdownButtonFormField<String>(
                    value: _zoneId,
                    decoration: const InputDecoration(labelText: 'Seleccionar zona'),
                    items: _zones
                        .map((z) => DropdownMenuItem(value: z.id, child: Text('${z.name} · ${z.clientsCount} clientes')))
                        .toList(),
                    onChanged: (value) => setState(() => _zoneId = value),
                  ),
                ),
                Step(
                  isActive: _step >= 1,
                  title: const Text('Pedidos de la zona'),
                  content: _pendingOrders.isEmpty
                      ? const _EmptyRouteState()
                      : Column(
                          children: _pendingOrders
                              .map(
                                (o) => Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: CheckboxListTile(
                                    value: _selectedOrderIds.contains(o.orderId.isNotEmpty ? o.orderId : o.id),
                                    onChanged: (value) => setState(() {
                                      final selectedId = o.orderId.isNotEmpty ? o.orderId : o.id;
                                      if (value == true) {
                                        _selectedOrderIds.add(selectedId);
                                      } else {
                                        _selectedOrderIds.remove(selectedId);
                                      }
                                    }),
                                    title: Text('#${o.orderNumber ?? '-'} · ${o.clientName}'),
                                    subtitle: Text(
                                      '${o.addressLine ?? '-'}\n${o.clientPhone ?? '-'} · ${o.paymentTerms == 'cuenta_corriente' ? 'Cuenta corriente' : 'Contado'}\nTotal ${_money(o.total)} · Saldo ${_money(o.currentBalance ?? 0)}',
                                    ),
                                    isThreeLine: true,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
                Step(
                  isActive: _step >= 2,
                  title: const Text('Asignar repartidor'),
                  content: DropdownButtonFormField<String>(
                    value: _driverId,
                    decoration: const InputDecoration(labelText: 'Repartidor'),
                    items: _drivers
                        .map((d) => DropdownMenuItem(value: d.id, child: Text(d.fullName)))
                        .toList(),
                    onChanged: (value) => setState(() => _driverId = value),
                  ),
                ),
                Step(
                  isActive: _step >= 3,
                  title: const Text('Confirmación'),
                  content: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pedidos seleccionados: ${_selectedOrderIds.length}'),
                        Text('Total estimado de reparto: ${_money(totalToCollect)}'),
                        const SizedBox(height: 8),
                        const Text('Solo se incluyen pedidos preparados o pendientes de reparto de esta zona.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _create() async {
    if (_zoneId == null || _driverId == null || _selectedOrderIds.isEmpty) return;
    setState(() => _saving = true);
    try {
      final created = await context.read<DeliveryRepository>().create(
            zoneId: _zoneId!,
            orderIds: _selectedOrderIds.toList(),
            driverId: _driverId,
          );
      if (!mounted) return;
      Navigator.pop(context, created.id);
    } catch (_) {
      _msg('No pudimos crear el reparto. Verificá los pedidos seleccionados.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';
}

class _EmptyRouteState extends StatelessWidget {
  const _EmptyRouteState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No hay pedidos disponibles para esta zona.', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Asegurate de tener pedidos preparados o pendientes de reparto sin asignación activa.'),
        ],
      ),
    );
  }
}
