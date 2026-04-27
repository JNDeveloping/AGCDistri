import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import 'order_detail_page.dart';
import 'order_form_page.dart';

class PedidosPage extends StatefulWidget {
  const PedidosPage({super.key});

  static const path = '/pedidos';
  static const name = 'pedidos';

  @override
  State<PedidosPage> createState() => _PedidosPageState();
}

class _PedidosPageState extends State<PedidosPage> {
  final _search = TextEditingController();
  final _scrollController = ScrollController();
  static const _pageSize = 15;
  int _visibleItems = _pageSize;

  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().load();
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
                    hintText: 'Buscar pedido por número o cliente',
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
                      _chip('Todos', null),
                      _chip('Pendiente', 'pendiente'),
                      _chip('Preparado', 'preparado'),
                      _chip('En reparto', 'en_reparto'),
                      _chip('Entregado', 'entregado'),
                    ],
                  ),
                ),
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
              final visibleCount = state.items.length < _visibleItems ? state.items.length : _visibleItems;
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: visibleCount,
                itemBuilder: (_, i) {
                  final o = state.items[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id))),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [Expanded(child: Text('Pedido #${o.orderNumber}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))), _statusBadge(o.status)]),
                            const SizedBox(height: 6),
                            Text(o.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 6,
                              children: [
                                _infoPill(icon: Icons.attach_money_rounded, label: _money(o.total)),
                                _infoPill(icon: Icons.inventory_2_outlined, label: '${o.itemsCount} productos'),
                                _infoPill(icon: Icons.format_list_numbered_rounded, label: '${o.totalUnits.toStringAsFixed(0)} unidades'),
                                _infoPill(icon: Icons.payments_outlined, label: o.paymentTerms == 'cuenta_corriente' ? 'Cta. cte.' : 'Contado'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final selected = context.watch<OrdersCubit>().state.statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => context.read<OrdersCubit>().setStatusFilter(value)),
    );
  }

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
