import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/client_repository.dart';
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
  final _scrollController = ScrollController();
  static const _pageSize = 20;
  int _visibleItems = _pageSize;
  List<ClientZone> _zones = const [];

  @override
  void initState() {
    super.initState();
    context.read<ClientsCubit>().load();
    _loadZones();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    if (current >= (max - 200)) {
      setState(() => _visibleItems += _pageSize);
    }
  }

  Future<void> _loadZones() async {
    final zones = await context.read<ClientsCubit>().listZones(includeInactive: false);
    if (mounted) setState(() => _zones = zones);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canEdit = role == 'admin' || role == 'vendedor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          if (role == 'admin')
            TextButton.icon(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ZonesManagementPage(canManage: true)));
                if (mounted) await context.read<ClientsCubit>().load(forceRefresh: true);
              },
              icon: const Icon(Icons.route),
              label: const Text('Zonas'),
            ),
        ],
      ),
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
                  onChanged: (value) {
                    context.read<ClientsCubit>().onSearchChanged(value);
                    setState(() => _visibleItems = _pageSize);
                  },
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre, código, teléfono, localidad o zona',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: context.watch<ClientsCubit>().state.zoneId,
                  decoration: const InputDecoration(labelText: 'Zona / Ruta'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                    ..._zones.map((z) => DropdownMenuItem<String?>(value: z.id, child: Text(z.name))),
                  ],
                  onChanged: (value) {
                    context.read<ClientsCubit>().setZoneFilter(value);
                    setState(() => _visibleItems = _pageSize);
                  },
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
                  return _EmptyState(
                    icon: Icons.groups_rounded,
                    title: 'No hay clientes para mostrar',
                    subtitle: 'Probá limpiar filtros o crear un cliente nuevo.',
                    actionLabel: canEdit ? 'Nuevo cliente' : null,
                    onAction: canEdit ? () => _openForm(context) : null,
                  );
                }

                final visibleCount = state.items.length < _visibleItems ? state.items.length : _visibleItems;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: visibleCount,
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
      await context.read<ClientsCubit>().load(forceRefresh: true);
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
      } on ClientException catch (error) {
        if (!context.mounted) return;
        if (error.canDeactivate) {
          final action = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('No se puede eliminar'),
              content: const Text('Este cliente tiene movimientos asociados y no se puede eliminar. Podés desactivarlo.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cerrar')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desactivar cliente')),
              ],
            ),
          );
          if (action == true) {
            await context.read<ClientsCubit>().deactivate(id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente desactivado.')));
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
