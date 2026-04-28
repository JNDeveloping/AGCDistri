import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../accounts/presentation/pages/client_account_page.dart';
import '../../domain/models/client_model.dart';
import '../utils/whatsapp_utils.dart';
import '../cubit/clients_cubit.dart';

class ClientDetailPage extends StatefulWidget {
  const ClientDetailPage({required this.clientId, super.key});

  final String clientId;

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  late Future<ClientModel> _future;
  bool _updatingLocation = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<ClientsCubit>().getById(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'repartidor');
    final canEdit = role == 'admin' || role == 'vendedor';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del cliente')),
      body: FutureBuilder<ClientModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('No se pudo cargar el cliente.'));
          }

          final client = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: Text(client.businessName, style: Theme.of(context).textTheme.headlineSmall)),
                  Chip(
                    label: Text(client.isActive ? 'Activo' : 'Inactivo'),
                    backgroundColor: client.isActive ? Colors.green.shade100 : Colors.red.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Código: ${client.internalCode}'),
              Row(children: [Expanded(child: Text('Teléfono: ${client.phone}')), if (buildWhatsappUrl(client.phone) != null) IconButton(onPressed: () async { final ok = await openClientWhatsapp(client.phone); if (context.mounted && !ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp.'))); } }, icon: const Icon(Icons.chat), tooltip: 'WhatsApp')]),
              if (client.email != null) Text('Email: ${client.email}'),
              if (client.taxId != null) Text('CUIT: ${client.taxId}'),
              const Divider(height: 30),
              Text('Dirección: ${client.addressLine}'),
              Text('Localidad: ${client.city}'),
              Text('Provincia: ${client.province}'),
              Text('Zona/Ruta: ${client.zoneName ?? client.routeZone}'),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(client.latitude != null && client.longitude != null ? 'Ubicación guardada' : 'Ubicación no guardada'),
                  subtitle: client.latitude != null && client.longitude != null
                      ? Text(
                          'Latitud: ${client.latitude!.toStringAsFixed(6)}\nLongitud: ${client.longitude!.toStringAsFixed(6)}',
                        )
                      : const Text('Este cliente todavía no tiene coordenadas guardadas.'),
                  isThreeLine: client.latitude != null && client.longitude != null,
                  trailing: canEdit
                      ? FilledButton.tonal(
                          onPressed: _updatingLocation ? null : () => _updateLocation(client),
                          child: Text(_updatingLocation ? 'Actualizando...' : 'Actualizar ubicación'),
                        )
                      : null,
                ),
              ),
              const Divider(height: 30),
              Text('IVA: ${client.vatCondition}'),
              Text('Límite crédito: ${client.creditLimit.toStringAsFixed(2)}'),
              Text('Saldo actual: ${client.currentBalance.toStringAsFixed(2)}'),
              Text('Estado: ${client.isActive ? 'Activo' : 'Inactivo'}'),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Cuenta corriente'),
                  subtitle: Text(client.currentBalance > 0 ? 'Debe' : (client.currentBalance < 0 ? 'Saldo a favor' : 'Al día')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientAccountPage(clientId: client.id, clientName: client.businessName),
                    ),
                  ),
                ),
              ),
              if (client.notes != null) ...[
                const SizedBox(height: 16),
                const Text('Observaciones'),
                Text(client.notes!),
              ],
              if (canEdit) ...[
                const SizedBox(height: 20),
                FilledButton.tonalIcon(
                  onPressed: () => _toggleStatus(client),
                  icon: Icon(client.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded),
                  label: Text(client.isActive ? 'Desactivar' : 'Activar'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateLocation(ClientModel client) async {
    setState(() => _updatingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS apagado. Activá la ubicación del dispositivo.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await context.read<ClientsCubit>().saveClient(
            id: client.id,
            payload: client.copyWith(latitude: position.latitude, longitude: position.longitude),
          );

      if (!mounted) return;
      setState(() => _future = context.read<ClientsCubit>().getById(widget.clientId));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ubicación guardada correctamente')));
    } catch (error) {
      if (!mounted) return;
      final message = error.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message.contains('denegado')
                ? 'Permiso de ubicación denegado.'
                : message.contains('GPS apagado')
                    ? 'GPS apagado. Activá la ubicación del dispositivo.'
                    : 'No se pudo obtener ubicación.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _updatingLocation = false);
    }
  }

  Future<void> _toggleStatus(ClientModel client) async {
    final shouldDeactivate = client.isActive;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(shouldDeactivate ? 'Desactivar cliente' : 'Activar cliente'),
        content: Text(
          shouldDeactivate
              ? '¿Querés desactivar este cliente?'
              : '¿Querés volver a activar este cliente?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(shouldDeactivate ? 'Desactivar' : 'Activar')),
        ],
      ),
    );

    if (result == true) {
      if (shouldDeactivate) {
        await context.read<ClientsCubit>().deactivate(client.id);
      } else {
        await context.read<ClientsCubit>().activate(client.id);
      }
      if (mounted) {
        setState(() => _future = context.read<ClientsCubit>().getById(widget.clientId));
      }
    }
  }
}
