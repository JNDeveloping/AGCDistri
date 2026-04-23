import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../domain/models/client_model.dart';
import '../cubit/clients_cubit.dart';
import '../cubit/clients_state.dart';
import '../widgets/client_card.dart';
import 'client_detail_page.dart';
import 'client_form_page.dart';

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
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
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
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, negocio, teléfono, localidad o código',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              context.read<ClientsCubit>().onSearchChanged('');
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
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
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 36),
                        const SizedBox(height: 10),
                        Text(state.errorMessage ?? 'No se pudieron cargar clientes'),
                        TextButton(
                          onPressed: () => context.read<ClientsCubit>().load(),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  return const Center(child: Text('No hay clientes para mostrar.'));
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<ClientsCubit>().load(),
                  child: ListView.builder(
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
                      );
                    },
                  ),
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
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClientDetailPage(clientId: id)),
    );
  }
}
