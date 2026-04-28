import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../accounts/presentation/pages/accounts_overview_page.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../pedidos/presentation/pages/order_detail_page.dart';
import '../../../pedidos/presentation/pages/pedidos_page.dart';
import '../../../productos/presentation/pages/productos_page.dart';
import '../../data/repositories/reports_repository.dart';
import '../widgets/reports_filter_bar.dart';
import '../widgets/simple_bar_chart.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  static const path = '/reportes';
  static const name = 'reportes';

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  ReportsFilters _filters = const ReportsFilters(period: 'month');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit c) => c.state.session?.user.role ?? 'vendedor');
    if (role == 'repartidor') {
      return Scaffold(
        appBar: AppBar(title: const Text('Reportes')),
        body: const Center(child: Text('No tenés permisos para este módulo.')),
      );
    }

    final repo = context.read<ReportsRepository>();
    final query = _filters.toQuery();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Ventas'),
            Tab(text: 'Deuda'),
            Tab(text: 'Pagos'),
            Tab(text: 'Productos'),
            Tab(text: 'Ganancias'),
            Tab(text: 'Zonas'),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentRoute: ReportsPage.path, role: role),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: ReportsFilterBar(
              filters: _filters,
              onFiltersChanged: (filters) => setState(() => _filters = filters),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SalesTab(repo: repo, query: query),
                _DebtTab(repo: repo, query: query),
                _PaymentsTab(repo: repo, query: query),
                _TopProductsTab(repo: repo, query: query),
                _ProfitTab(repo: repo, query: query),
                _ZonesTab(repo: repo, query: query),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesTab extends StatelessWidget {
  const _SalesTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.sales(query),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingView();
        if (!snapshot.hasData) return _ErrorView(message: 'No se pudo cargar ventas.');
        final data = snapshot.data!;
        final totals = data['totals'] as Map<String, dynamic>? ?? {};
        final byDay = (data['byDay'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final byZone = (data['byZone'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final bySeller = (data['bySeller'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SectionCard(
              title: 'Resumen de ventas',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricTile(title: 'Total vendido', value: '\$${(totals['sales'] ?? 0).toString()}'),
                  _MetricTile(title: 'Pedidos', value: '${totals['orders'] ?? 0}'),
                  _MetricTile(title: 'Ticket promedio', value: '\$${(totals['avgTicket'] ?? 0).toString()}'),
                ],
              ),
            ),
            _SectionCard(
              title: 'Ventas por día',
              child: SimpleBarChart(values: byDay.map((e) => (e['sales'] as num?)?.toDouble() ?? 0).toList()),
            ),
            _SectionCard(
              title: 'Ventas por zona',
              child: _SimpleList(
                items: byZone,
                titleKey: 'zone',
                trailingBuilder: (e) => '\$${e['sales'] ?? 0} · ${e['orders'] ?? 0} pedidos',
                onTap: (_) => context.go(PedidosPage.path),
              ),
            ),
            _SectionCard(
              title: 'Ventas por vendedor',
              child: _SimpleList(items: bySeller, titleKey: 'sellerName', trailingBuilder: (e) => '\$${e['sales'] ?? 0}'),
            ),
          ],
        );
      },
    );
  }
}

class _DebtTab extends StatelessWidget {
  const _DebtTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.debt(query),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingView();
        if (!snapshot.hasData) return _ErrorView(message: 'No se pudo cargar deuda.');
        final data = snapshot.data!;
        final top = (data['topDebtors'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final byZone = (data['debtByZone'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final recent = (data['recentMovements'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SectionCard(
              title: 'Resumen de deuda',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricTile(title: 'Deuda total', value: '\$${data['totalDebt'] ?? 0}'),
                  _MetricTile(title: 'Clientes con deuda', value: '${data['clientsWithDebt'] ?? 0}'),
                ],
              ),
            ),
            _SectionCard(
              title: 'Top clientes deudores',
              child: _SimpleList(
                items: top,
                titleKey: 'businessName',
                trailingBuilder: (e) => '\$${e['balance'] ?? 0}',
                onTap: (_) => context.go('${AccountsOverviewPage.path}?filter=with_debt'),
              ),
            ),
            _SectionCard(
              title: 'Deuda por zona',
              child: _SimpleList(items: byZone, titleKey: 'zone', trailingBuilder: (e) => '\$${e['debt'] ?? 0}'),
            ),
            _SectionCard(
              title: 'Movimientos recientes',
              child: _SimpleList(
                items: recent,
                titleKey: 'businessName',
                trailingBuilder: (e) => '${e['movementType']} · \$${e['amount']}',
                onTap: (e) {
                  if (e['referenceType'] == 'order' && (e['referenceId']?.toString().isNotEmpty ?? false)) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: '${e['referenceId']}')));
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.payments(query),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingView();
        if (!snapshot.hasData) return _ErrorView(message: 'No se pudo cargar pagos.');
        final data = snapshot.data!;
        final byMethod = (data['byMethod'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final byUser = (data['byUser'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final recent = (data['recent'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SectionCard(
              title: 'Resumen de pagos',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricTile(title: 'Pagos del día', value: '\$${(data['today']?['amount'] ?? 0)}'),
                  _MetricTile(title: 'Pagos del mes', value: '\$${(data['month']?['amount'] ?? 0)}'),
                  _MetricTile(title: 'Cantidad filtrada', value: '${(data['totals']?['count'] ?? 0)}'),
                ],
              ),
            ),
            _SectionCard(
              title: 'Por método',
              child: _SimpleList(items: byMethod, titleKey: 'method', trailingBuilder: (e) => '\$${e['total'] ?? 0} · ${e['count'] ?? 0}'),
            ),
            _SectionCard(
              title: 'Por usuario',
              child: _SimpleList(items: byUser, titleKey: 'userName', trailingBuilder: (e) => '\$${e['total'] ?? 0} · ${e['count'] ?? 0}'),
            ),
            _SectionCard(
              title: 'Historial reciente',
              child: _SimpleList(
                items: recent,
                titleKey: 'businessName',
                trailingBuilder: (e) => '${e['method']} · \$${e['amount']}',
                onTap: (_) => context.go('${AccountsOverviewPage.path}?filter=with_debt'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopProductsTab extends StatelessWidget {
  const _TopProductsTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.topProducts(query),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingView();
        if (!snapshot.hasData) return _ErrorView(message: 'No se pudo cargar productos.');
        final data = snapshot.data!;
        final topQty = (data['topByQuantity'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final topRevenue = (data['topByRevenue'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final noRecent = (data['noRecentSales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SectionCard(
              title: 'Productos por cantidad vendida',
              child: _SimpleList(
                items: topQty,
                titleKey: 'productName',
                trailingBuilder: (e) => '${e['quantity']} u · \$${e['revenue']}',
                onTap: (_) => context.go(ProductosPage.path),
              ),
            ),
            _SectionCard(
              title: 'Productos por facturación',
              child: _SimpleList(items: topRevenue, titleKey: 'productName', trailingBuilder: (e) => '\$${e['revenue']}'),
            ),
            _SectionCard(
              title: 'Sin ventas recientes',
              child: _SimpleList(items: noRecent, titleKey: 'productName', trailingBuilder: (e) => '${e['lastSale'] ?? 'Sin ventas'}'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfitTab extends StatelessWidget {
  const _ProfitTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.profit(query),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingView();
        if (!snapshot.hasData) return _ErrorView(message: 'No se pudo cargar ganancias.');
        final data = snapshot.data!;
        final totals = data['totals'] as Map<String, dynamic>? ?? {};
        final byProduct = (data['byProduct'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final byCategory = (data['byCategory'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final byZone = (data['byZone'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _SectionCard(
              title: 'Resumen de ganancias',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetricTile(title: 'Venta total', value: '\$${totals['salesTotal'] ?? 0}'),
                  _MetricTile(title: 'Costo estimado', value: '\$${totals['costTotal'] ?? 0}'),
                  _MetricTile(title: 'Ganancia bruta', value: '\$${totals['grossProfit'] ?? 0}'),
                  _MetricTile(title: 'Margen promedio', value: '${totals['avgMargin'] ?? 0}%'),
                ],
              ),
            ),
            _SectionCard(
              title: 'Ganancia por producto',
              child: _SimpleList(items: byProduct, titleKey: 'productName', trailingBuilder: (e) => '\$${e['profit']}'),
            ),
            _SectionCard(
              title: 'Ganancia por categoría',
              child: _SimpleList(items: byCategory, titleKey: 'category', trailingBuilder: (e) => '\$${e['profit']}'),
            ),
            _SectionCard(
              title: 'Ganancia por zona',
              child: _SimpleList(items: byZone, titleKey: 'zone', trailingBuilder: (e) => '\$${e['profit']}'),
            ),
          ],
        );
      },
    );
  }
}

class _ZonesTab extends StatelessWidget {
  const _ZonesTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.zones(query),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const _LoadingView();
        if (!snapshot.hasData) return _ErrorView(message: 'No se pudo cargar zonas.');
        final zones = snapshot.data!;
        if (zones.isEmpty) return const _EmptyView(message: 'Sin datos de zonas para los filtros actuales.');
        return ListView(
          padding: const EdgeInsets.all(12),
          children: zones
              .map(
                (z) => Card(
                  elevation: 0,
                  child: ListTile(
                    leading: const Icon(Icons.route_rounded),
                    title: Text('${z['zone']}'),
                    subtitle: Text('Ventas: \$${z['sales']} · Pedidos: ${z['orders']} · Deuda: \$${z['debt']} · Clientes: ${z['clients']}'),
                    trailing: Text('Unid: ${z['soldUnits']}'),
                    onTap: () => context.go('${PedidosPage.path}?zoneId=${z['zoneId']}'),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
    );
  }
}

class _SimpleList extends StatelessWidget {
  const _SimpleList({
    required this.items,
    required this.titleKey,
    required this.trailingBuilder,
    this.onTap,
  });

  final List<Map<String, dynamic>> items;
  final String titleKey;
  final String Function(Map<String, dynamic> item) trailingBuilder;
  final void Function(Map<String, dynamic> item)? onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const _EmptyView(message: 'Sin datos para esta sección.');
    return Column(
      children: items
          .take(12)
          .map(
            (e) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${e[titleKey] ?? '-'}'),
              trailing: Text(trailingBuilder(e), textAlign: TextAlign.right),
              onTap: onTap == null ? null : () => onTap!(e),
            ),
          )
          .toList(),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: List.generate(
        5,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 88,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
    );
  }
}
