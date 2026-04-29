import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../clientes/data/repositories/client_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../domain/models/order_model.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import 'order_detail_page.dart';
import 'order_form_page.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({this.initialZoneId, this.initialStatusFilter, super.key});

  static const path = '/pedidos';
  static const name = 'pedidos';
  final String? initialZoneId;
  final String? initialStatusFilter;

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  static const _pageSize = 15;
  int _visibleItems = _pageSize;
  List<ClientZone> _zones = const [];

  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().load();
    _loadZones();
    if (widget.initialZoneId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OrdersCubit>().setZoneFilter(widget.initialZoneId);
      });
    }
    if (widget.initialStatusFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<OrdersCubit>().setStatusFilter(widget.initialStatusFilter);
      });
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >= (_scrollController.position.maxScrollExtent - 200)) {
      setState(() => _visibleItems += _pageSize);
    }
  }

  Future<void> _loadZones() async {
    final zones = await context.read<ClientRepository>().listZones(includeInactive: false);
    if (mounted) setState(() => _zones = zones);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canCreate = role == 'admin' || role == 'vendedor';

    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos')),
      bottomNavigationBar: AppBottomNavBar(currentRoute: PedidosPage.path, role: role),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OrderFormPage()));
                if (saved == true && mounted) await context.read<OrdersCubit>().load(forceRefresh: true);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nuevo pedido'),
            )
          : null,
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: (value) {
                    context.read<OrdersCubit>().onSearch(value);
                    setState(() => _visibleItems = _pageSize);
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar: pedido, cliente, teléfono, zona, producto',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              _search.clear();
                              context.read<OrdersCubit>().onSearch('');
                              setState(() => _visibleItems = _pageSize);
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('Todos', null, _totalCount()),
                      _chip('Pendientes', 'pendiente', _count('pendiente')),
                      _chip('Preparados', 'preparado', _count('preparado')),
                      _chip('En reparto', 'en_reparto', _count('en_reparto')),
                      _chip('Entregados', 'entregado', _count('entregado')),
                      _chip('Cancelados', 'cancelado', _count('cancelado')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _filtersRow(),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(builder: (_, state) {
              if (state.status == OrdersStatus.loading && state.items.isEmpty) return const Center(child: CircularProgressIndicator());
              if (state.status == OrdersStatus.failure) return Center(child: Text(state.errorMessage ?? 'No se pudo cargar pedidos'));
              if (state.items.isEmpty) {
                return _EmptyState(
                  icon: Icons.shopping_cart_checkout_rounded,
                  title: 'No hay pedidos todavía',
                  subtitle: canCreate ? 'Creá tu primer pedido para empezar.' : 'No hay pedidos para mostrar.',
                  actionLabel: canCreate ? 'Nuevo pedido' : null,
                  onAction: canCreate
                      ? () async {
                          final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const OrderFormPage()));
                          if (saved == true && mounted) await context.read<OrdersCubit>().load(forceRefresh: true);
                        }
                      : null,
                );
              }
              final grouped = _groupOrders(state.items, state.groupBy);
              final visibleCount = grouped.length < _visibleItems ? grouped.length : _visibleItems;
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: visibleCount,
                itemBuilder: (_, i) {
                  final group = grouped[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state.groupBy != 'none') ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, top: 4),
                          child: Text(group.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ],
                      ...group.$2.map((order) => _orderCard(order, role)),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value, int count) {
    final selected = context.watch<OrdersCubit>().state.statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text('$label ($count)'), selected: selected, onSelected: (_) => context.read<OrdersCubit>().setStatusFilter(value)),
    );
  }

  Widget _filtersRow() {
    final cubit = context.read<OrdersCubit>();
    final state = context.watch<OrdersCubit>().state;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          PopupMenuButton<String>(
            tooltip: 'Fecha',
            onSelected: (value) {
              final now = DateTime.now();
              String? from;
              String? to;
              if (value == 'today') {
                from = _ymd(now); to = _ymd(now);
              } else if (value == 'yesterday') {
                final y = now.subtract(const Duration(days: 1));
                from = _ymd(y); to = _ymd(y);
              } else if (value == 'week') {
                final fromDate = now.subtract(Duration(days: now.weekday - 1));
                from = _ymd(fromDate); to = _ymd(now);
              } else if (value == 'month') {
                final fromDate = DateTime(now.year, now.month, 1);
                from = _ymd(fromDate); to = _ymd(now);
              }
              cubit.setDateRange(from: from, to: to);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'today', child: Text('Hoy')),
              PopupMenuItem(value: 'yesterday', child: Text('Ayer')),
              PopupMenuItem(value: 'week', child: Text('Esta semana')),
              PopupMenuItem(value: 'month', child: Text('Este mes')),
            ],
            child: _filterChip('Fecha'),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String?>(
            tooltip: 'Pago',
            onSelected: (value) => cubit.setPaymentCondition(value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('Todos')),
              PopupMenuItem(value: 'contado', child: Text('Contado')),
              PopupMenuItem(value: 'cuenta_corriente', child: Text('Cuenta corriente')),
            ],
            child: _filterChip(state.paymentCondition == null ? 'Pago' : state.paymentCondition!),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Archivado',
            onSelected: (value) => cubit.setArchivedFilter(value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'active', child: Text('Activos')),
              PopupMenuItem(value: 'archived', child: Text('Archivados')),
              PopupMenuItem(value: 'all', child: Text('Todos')),
            ],
            child: _filterChip(
              state.archived == 'archived' ? 'Archivados' : state.archived == 'all' ? 'Todos' : 'Activos',
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Ordenar por',
            onSelected: (value) {
              final parts = value.split('|');
              cubit.setSorting(sortBy: parts[0], sortDirection: parts[1]);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'orderDate|desc', child: Text('Más recientes primero')),
              PopupMenuItem(value: 'orderDate|asc', child: Text('Más antiguos primero')),
              PopupMenuItem(value: 'total|desc', child: Text('Mayor importe')),
              PopupMenuItem(value: 'total|asc', child: Text('Menor importe')),
              PopupMenuItem(value: 'client|asc', child: Text('Cliente A-Z')),
              PopupMenuItem(value: 'zone|asc', child: Text('Zona/Ruta')),
              PopupMenuItem(value: 'status|asc', child: Text('Estado')),
            ],
            child: _filterChip('Ordenar'),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Agrupar',
            onSelected: (value) => cubit.setGroupBy(value),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'none', child: Text('Sin agrupar')),
              PopupMenuItem(value: 'zone', child: Text('Por zona')),
              PopupMenuItem(value: 'status', child: Text('Por estado')),
              PopupMenuItem(value: 'date', child: Text('Por fecha')),
              PopupMenuItem(value: 'client', child: Text('Por cliente')),
            ],
            child: _filterChip('Agrupar'),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String?>(
            tooltip: 'Zona',
            onSelected: (value) => cubit.setZoneFilter(value),
            itemBuilder: (_) => [
              const PopupMenuItem<String?>(value: null, child: Text('Todas las zonas')),
              ..._zones.map((z) => PopupMenuItem<String?>(value: z.id, child: Text(z.name))),
            ],
            child: _filterChip(
              _zones.where((z) => z.id == state.zoneId).isNotEmpty
                  ? _zones.firstWhere((z) => z.id == state.zoneId).name
                  : 'Zona/Ruta',
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) => Chip(label: Text(label), visualDensity: VisualDensity.compact);

  Widget _statusBadge(String status) {
    final colors = Theme.of(context).colorScheme;
    final bg = switch (status) {
      'pendiente' => colors.secondaryContainer,
      'preparado' => Colors.amber.shade100,
      'en_reparto' => Colors.deepPurple.shade100,
      'entregado' => Colors.green.shade100,
      _ => Colors.red.shade100,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(status, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _infoPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }

  String _money(double value) => String.fromCharCode(36) + value.toStringAsFixed(2);

  int _count(String status) => context.watch<OrdersCubit>().state.countsByStatus[status] ?? 0;
  int _totalCount() => context.watch<OrdersCubit>().state.countsByStatus.values.fold(0, (a, b) => a + b);

  String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<(String, List<OrderModel>)> _groupOrders(List<OrderModel> items, String groupBy) {
    if (groupBy == 'none') return [('Pedidos', items)];
    final map = <String, List<OrderModel>>{};
    for (final o in items) {
      final key = switch (groupBy) {
        'zone' => o.zoneName ?? 'Sin zona',
        'status' => o.status,
        'date' => o.orderDate == null ? 'Sin fecha' : _ymd(o.orderDate!.toLocal()),
        'client' => o.clientName,
        _ => 'Pedidos',
      };
      map.putIfAbsent(key, () => []).add(o);
    }
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => (e.key, e.value)).toList();
  }

  Widget _orderCard(OrderModel o, String role) {
    final canCancel = role == 'admin' || role == 'vendedor';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Expanded(child: Text('Pedido #${o.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))), _statusBadge(o.status)]),
            const SizedBox(height: 6),
            Text(o.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('${o.zoneName ?? 'Sin zona'} · ${o.orderDate?.toLocal().toString().split(' ').first ?? '-'}'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _infoPill(icon: Icons.attach_money_rounded, label: _money(o.total)),
                _infoPill(icon: Icons.inventory_2_outlined, label: '${o.itemsCount} productos'),
                _infoPill(icon: Icons.format_list_numbered_rounded, label: '${o.totalUnits.toStringAsFixed(0)} unidades'),
                _infoPill(icon: Icons.payments_outlined, label: o.paymentTerms == 'cuenta_corriente' ? 'Cta. cte.' : 'Contado'),
                if (o.hasCreditNotes) _infoPill(icon: Icons.receipt_long_rounded, label: 'NC'),
                if (o.paymentTerms == 'cuenta_corriente') _infoPill(icon: Icons.account_balance_wallet_rounded, label: 'Cuenta corriente'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id)));
                    if (mounted) {
                      await context.read<OrdersCubit>().load(forceRefresh: true);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listado de pedidos actualizado.')));
                    }
                  },
                  child: const Text('Ver detalle'),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    try {
                      await context.read<OrdersCubit>().changeStatus(o.id, v);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Estado actualizado correctamente.')),
                      );
                    } on OrderException catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'preparado', child: Text('Preparado')),
                  ],
                  enabled: o.status == 'pendiente',
                  child: Chip(
                    label: Text(o.status == 'pendiente' ? 'Cambiar estado' : 'Solo desde pendiente'),
                  ),
                ),
                if (canCancel && o.status != 'cancelado')
                  OutlinedButton(
                    onPressed: () => context.read<OrdersCubit>().cancel(o.id),
                    child: const Text('Cancelar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
            Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
