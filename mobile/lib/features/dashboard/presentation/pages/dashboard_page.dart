import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../accounts/presentation/pages/accounts_overview_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../pedidos/presentation/pages/pedidos_page.dart';
import '../../../productos/presentation/pages/productos_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../stock/presentation/pages/stock_page.dart';
import '../../domain/models/dashboard_stats.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static const path = '/dashboard';
  static const name = 'dashboard';

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          GestureDetector(
            onTap: () => context.go(ProfilePage.path),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                child: Text(
                  (context.read<AuthCubit>().state.session?.user.fullName ?? 'U')[0].toUpperCase(),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentRoute: DashboardPage.path, role: role),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.loading || state.status == DashboardStatus.initial) {
            return const _DashboardLoading();
          }

          if (state.status == DashboardStatus.failure || state.stats == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 40),
                  const SizedBox(height: 8),
                  Text(state.errorMessage ?? 'No se pudieron cargar métricas'),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () => context.read<DashboardCubit>().load(), child: const Text('Reintentar')),
                ],
              ),
            );
          }

          final stats = state.stats!;
          return RefreshIndicator(
            onRefresh: () => context.read<DashboardCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                _sectionTitle(context, 'Resumen del día'),
                const SizedBox(height: 8),
                _cardsGrid(
                  context,
                  [
                    _DashboardMetric(
                      title: 'Ventas del día',
                      value: _money(stats.salesToday),
                      icon: Icons.point_of_sale_rounded,
                      color: Colors.green,
                    ),
                    _DashboardMetric(
                      title: 'Pagos recibidos hoy',
                      value: '${stats.paymentsToday}',
                      subtitle: 'Total: ${_money(stats.collectedToday)}',
                      icon: Icons.payments_rounded,
                      color: Colors.teal,
                      onTap: () => context.go('${AccountsOverviewPage.path}?filter=with_debt'),
                    ),
                    _DashboardMetric(
                      title: 'Ventas del mes',
                      value: _money(stats.salesMonth),
                      icon: Icons.calendar_month_rounded,
                      color: Colors.blue,
                    ),
                    _DashboardMetric(
                      title: 'Ganancia estimada',
                      value: _money(stats.profitEstimate),
                      icon: Icons.trending_up_rounded,
                      color: Colors.indigo,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle(context, 'Pedidos'),
                const SizedBox(height: 8),
                _cardsGrid(
                  context,
                  [
                    _DashboardMetric(
                      title: 'Pendientes',
                      value: '${stats.pendingOrders}',
                      icon: Icons.schedule_rounded,
                      color: Colors.orange,
                      onTap: () => context.go('${PedidosPage.path}?status=pendiente'),
                    ),
                    _DashboardMetric(
                      title: 'Preparados',
                      value: '${stats.preparedOrders}',
                      icon: Icons.inventory_2_rounded,
                      color: Colors.deepPurple,
                      onTap: () => context.go('${PedidosPage.path}?status=preparado'),
                    ),
                    _DashboardMetric(
                      title: 'En reparto',
                      value: '${stats.deliveryOrders}',
                      icon: Icons.local_shipping_rounded,
                      color: Colors.blueGrey,
                      onTap: () => context.go('${PedidosPage.path}?status=en_reparto'),
                    ),
                    _DashboardMetric(
                      title: 'Entregados hoy',
                      value: '${stats.deliveredToday}',
                      icon: Icons.done_all_rounded,
                      color: Colors.green,
                      onTap: () => context.go('${PedidosPage.path}?status=entregado'),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                _sectionTitle(context, 'Reparto'),
                const SizedBox(height: 8),
                _cardsGrid(
                  context,
                  [
                    _DashboardMetric(
                      title: 'Repartos del día',
                      value: '${stats.deliveriesToday}',
                      icon: Icons.route_rounded,
                      color: Colors.cyan,
                    ),
                    _DashboardMetric(
                      title: 'Pedidos en reparto',
                      value: '${stats.ordersInDelivery}',
                      icon: Icons.local_shipping_rounded,
                      color: Colors.indigo,
                    ),
                    _DashboardMetric(
                      title: 'Entregados hoy',
                      value: '${stats.deliveredOrdersToday}',
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    _DashboardMetric(
                      title: 'No entregados',
                      value: '${stats.notDeliveredOrdersToday}',
                      icon: Icons.cancel_rounded,
                      color: Colors.red,
                    ),
                    _DashboardMetric(
                      title: 'Total a cobrar',
                      value: _money(stats.totalToCollect),
                      icon: Icons.request_quote_rounded,
                      color: Colors.deepOrange,
                    ),
                    _DashboardMetric(
                      title: 'Total cobrado',
                      value: _money(stats.totalCollectedDelivery),
                      icon: Icons.payments_rounded,
                      color: Colors.teal,
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                _sectionTitle(context, 'Clientes / Deuda'),
                const SizedBox(height: 8),
                _cardsGrid(
                  context,
                  [
                    _DashboardMetric(
                      title: 'Deuda total',
                      value: _money(stats.totalDebt),
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.redAccent,
                      onTap: () => context.go('${AccountsOverviewPage.path}?filter=with_debt'),
                    ),
                    _DashboardMetric(
                      title: 'Clientes con deuda',
                      value: '${stats.clientsWithDebt}',
                      icon: Icons.groups_rounded,
                      color: Colors.red,
                      onTap: () => context.go('${AccountsOverviewPage.path}?filter=with_debt'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _sectionTitle(context, 'Stock'),
                const SizedBox(height: 8),
                _cardsGrid(
                  context,
                  [
                    _DashboardMetric(
                      title: 'Sin stock',
                      value: '${stats.outOfStockProducts}',
                      icon: Icons.remove_shopping_cart_rounded,
                      color: Colors.red,
                      onTap: () => context.go('${StockPage.path}?filter=out'),
                    ),
                    _DashboardMetric(
                      title: 'Stock bajo',
                      value: '${stats.lowStockProducts}',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.orange,
                      onTap: () => context.go('${StockPage.path}?filter=low'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _topProductsSection(context, stats),
                const SizedBox(height: 18),
                _sectionTitle(context, 'Zonas'),
                const SizedBox(height: 8),
                _zonesSection(context, stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800));
  }

  Widget _cardsGrid(BuildContext context, List<_DashboardMetric> metrics) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final width = constraints.maxWidth;
        final columns = width > 900 ? 4 : (width > 600 ? 3 : 2);
        final cardWidth = (width - (12 * (columns - 1))) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics.map((metric) => SizedBox(width: cardWidth, child: _metricCard(context, metric))).toList(),
        );
      },
    );
  }

  Widget _metricCard(BuildContext context, _DashboardMetric metric) {
    final title = metric.title;
    final subtitle = metric.subtitle;
    final color = metric.color;
    final onTap = metric.onTap;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
            color: color.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(metric.icon, color: color),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(metric.value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 8),
                const Align(alignment: Alignment.centerRight, child: Icon(Icons.open_in_new_rounded, size: 18)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _topProductsSection(BuildContext context, DashboardStats stats) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded),
                const SizedBox(width: 8),
                Text('Top 3 productos más vendidos', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (stats.topProducts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Sin ventas este mes.'),
              )
            else
              ...stats.topProducts.asMap().entries.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(radius: 14, child: Text('${entry.key + 1}')),
                      title: Text(entry.value.productName),
                      subtitle: Text('Unidades: ${entry.value.units.toStringAsFixed(2)}'),
                    ),
                  ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.go(ProductosPage.path),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Ver productos'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _zonesSection(BuildContext context, DashboardStats stats) {
    if (stats.zones.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Text('No hay zonas configuradas o sin datos por ahora.'),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: stats.zones
            .map(
              (zone) => ListTile(
                leading: const Icon(Icons.route_rounded),
                title: Text(zone.zoneName),
                subtitle: Text(
                  'Ventas: ${_money(zone.sales)} · Pedidos: ${zone.orders} · Deuda: ${_money(zone.debt)} · Clientes: ${zone.clients}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: zone.zoneId.isEmpty ? null : () => context.go('${PedidosPage.path}?zoneId=${zone.zoneId}'),
              ),
            )
            .toList(),
      ),
    );
  }

  String _money(double value) => '\$${value.toStringAsFixed(2)}';
}

class _DashboardMetric {
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 20,
            width: 180,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              4,
              (_) => Container(
                width: 170,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
