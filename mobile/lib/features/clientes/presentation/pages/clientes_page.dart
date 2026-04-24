import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/client_model.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/client_card.dart';
import 'client_detail_page.dart';
import 'client_form_page.dart';
import 'zones_management_page.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  static const String path = '/clientes';
  static const String name = 'clientes';

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ClientsCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canEdit = role == 'admin' || role == 'vendedor';

    return Scaffold(
      appBar: AppBar(title: const Text('Clientes'), actions: [if (canEdit) TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ZonesManagementPage(canManage: role == 'admin'))), icon: const Icon(Icons.route), label: const Text('Zonas'))]),
      bottomNavigationBar: AppBottomNavBar(currentRoute: ClientesPage.path, role: role),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Nuevo cliente'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: context.read<ClientsCubit>().onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, negocio, teléfono, localidad o código',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Todos'),
                      selected: context.watch<ClientsCubit>().state.filteredStatus == null,
                      onSelected: (_) => context.read<ClientsCubit>().applyFilter(null),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Activos'),
                      selected: context.watch<ClientsCubit>().state.filteredStatus == true,
                      onSelected: (_) => context.read<ClientsCubit>().applyFilter(true),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Inactivos'),
                      selected: context.watch<ClientsCubit>().state.filteredStatus == false,
                      onSelected: (_) => context.read<ClientsCubit>().applyFilter(false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ClientsCubit, ClientsState>(
              builder: (context, state) {
                if (state.status == ClientsStatus.loading && state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == ClientsStatus.failure) {
                  return Center(child: Text(state.errorMessage ?? 'No se pudieron cargar clientes'));
                }

                if (state.items.isEmpty) {
                  return const Center(child: Text('No hay clientes para mostrar.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final client = state.items[index];
                    return ClientCard(
                      client: client,
                      canEdit: canEdit,
                      onTap: () => _openDetail(context, client.id),
                      onEdit: () => _openForm(context, client: client),
                      onDeactivate: () => _confirmDeactivate(context, client.id),
                      onDelete: () => _confirmDelete(context, client.id),
                      onActivate: () => _confirmActivate(context, client.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeactivate(BuildContext context, String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desactivar cliente'),
        content: const Text('El cliente quedará inactivo, pero se mantiene para históricos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desactivar')),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await context.read<ClientsCubit>().deactivate(id);
    }
  }

  Future<void> _openForm(BuildContext context, {ClientModel? client}) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClientFormPage(client: client)),
    );

    if (updated == true && context.mounted) {
      await context.read<ClientsCubit>().load();
    }
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientDetailPage(clientId: id)));
  }

  Future<void> _confirmActivate(BuildContext context, String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activar cliente'),
        content: const Text('¿Querés volver a activar este cliente?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Activar')),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await context.read<ClientsCubit>().activate(id);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cliente'),
        content: const Text(
          'Esta acción elimina físicamente el cliente si no tiene movimientos asociados. ¿Deseás continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await context.read<ClientsCubit>().delete(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente eliminado.')));
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }
  }
}
