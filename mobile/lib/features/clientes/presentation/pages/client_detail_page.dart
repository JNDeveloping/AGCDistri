import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/client_model.dart';
import '../cubit/clients_cubit.dart';

class ClientDetailPage extends StatelessWidget {
  const ClientDetailPage({required this.clientId, super.key});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del cliente')),
      body: FutureBuilder<ClientModel>(
        future: context.read<ClientsCubit>().getById(clientId),
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
              Text(client.businessName, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Código: ${client.internalCode}'),
              Text('Contacto: ${client.contactName}'),
              Text('Teléfono: ${client.phone}'),
              if (client.alternatePhone != null) Text('Teléfono alt.: ${client.alternatePhone}'),
              if (client.email != null) Text('Email: ${client.email}'),
              if (client.taxId != null) Text('CUIT: ${client.taxId}'),
              const Divider(height: 30),
              Text('Dirección: ${client.addressLine}'),
              Text('Localidad: ${client.city}'),
              Text('Provincia: ${client.province}'),
              Text('Zona/Ruta: ${client.routeZone}'),
              const Divider(height: 30),
              Text('IVA: ${client.vatCondition}'),
              Text('Límite crédito: ${client.creditLimit.toStringAsFixed(2)}'),
              Text('Saldo actual: ${client.currentBalance.toStringAsFixed(2)}'),
              Text('Estado: ${client.isActive ? 'Activo' : 'Inactivo'}'),
              if (client.notes != null) ...[
                const SizedBox(height: 16),
                const Text('Observaciones'),
                Text(client.notes!),
              ],
            ],
          );
        },
      ),
    );
  }
}
