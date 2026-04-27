import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../users/data/repositories/users_repository.dart';
import '../../../users/domain/models/app_user.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../domain/models/delivery_model.dart';

class DeliveryCreatePage extends StatefulWidget {
  const DeliveryCreatePage({super.key});

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
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
        _selectedOrderIds
          ..clear()
          ..addAll(rows.map((e) => e.orderId));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedOrders = _pendingOrders.where((o) => _selectedOrderIds.contains(o.orderId)).toList();
    final totalToCollect = selectedOrders.fold<double>(0, (acc, o) => acc + (o.total));

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
                  if (_zoneId == null) {
                    _msg('Seleccioná una zona.');
                    return;
                  }
                  await _loadPendingOrders();
                  setState(() => _step = 1);
                  return;
                }
                if (_step == 1) {
                  if (_selectedOrderIds.isEmpty) {
                    _msg('Seleccioná al menos un pedido.');
                    return;
                  }
                  setState(() => _step = 2);
                  return;
                }
                if (_step == 2) {
                  if (_driverId == null) {
                    _msg('Seleccioná repartidor.');
                    return;
                  }
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
                        .map((z) => DropdownMenuItem(
                              value: z.id,
                              child: Text('${z.name} · ${z.clientsCount} clientes'),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _zoneId = value),
                  ),
                ),
                Step(
                  isActive: _step >= 1,
                  title: const Text('Pedidos disponibles'),
                  content: _pendingOrders.isEmpty
                      ? const Text('No hay pedidos pendientes para esta zona.')
                      : Column(
                          children: _pendingOrders
                              .map(
                                (o) => Card(
                                  child: CheckboxListTile(
                                    value: _selectedOrderIds.contains(o.orderId),
                                    onChanged: (value) => setState(() {
                                      if (value == true) {
                                        _selectedOrderIds.add(o.orderId);
                                      } else {
                                        _selectedOrderIds.remove(o.orderId);
                                      }
                                    }),
                                    title: Text('#${o.orderNumber ?? '-'} · ${o.clientName}'),
                                    subtitle: Text('${o.addressLine ?? '-'}\n${o.clientPhone ?? '-'} · ${o.paymentTerms ?? '-'} · ${_money(o.total)}'),
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
                        .map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.fullName),
                            ))
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
                        Text('Total a cobrar: ${_money(totalToCollect)}'),
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
    } catch (e) {
      _msg(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _msg(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _money(double value) => String.fromCharCode(36) + value.toStringAsFixed(2);
}
