import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
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
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
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
    final query = {'period': _period};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes y Análisis'),
        actions: [
          IconButton(
            onPressed: () => _exportSummaryPdf(repo, query),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exportar PDF',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Resumen'),
            Tab(text: 'Ventas'),
            Tab(text: 'Ganancias'),
            Tab(text: 'Clientes'),
            Tab(text: 'Productos'),
            Tab(text: 'Deudores'),
            Tab(text: 'Stock'),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentRoute: ReportsPage.path, role: role),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ReportsFilterBar(
            period: _period,
            onPeriodChanged: (value) => setState(() => _period = value),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: MediaQuery.of(context).size.height - 210,
            child: TabBarView(
              controller: _tabController,
              children: [
                _SummaryTab(repo: repo, query: query),
                _SalesTab(repo: repo, query: query),
                _ProfitTab(repo: repo, query: query),
                _TopClientsTab(repo: repo, query: query),
                _TopProductsTab(repo: repo, query: query),
                _DebtorsTab(repo: repo, query: query),
                _StockTab(repo: repo, query: query),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSummaryPdf(ReportsRepository repo, Map<String, dynamic> query) async {
    try {
      final summary = await repo.summary(query);
      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (_) => [
            pw.Text('Reporte Resumen', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Período: $_period'),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: const ['Métrica', 'Valor'],
              data: [
                ['Ventas del día', '${summary['salesToday'] ?? 0}'],
                ['Ventas del mes', '${summary['salesMonth'] ?? 0}'],
                ['Ganancia estimada', '${summary['estimatedProfit'] ?? 0}'],
                ['Cantidad de pedidos', '${summary['ordersCount'] ?? 0}'],
                ['Ticket promedio', '${summary['avgTicket'] ?? 0}'],
                ['Clientes con deuda', '${summary['debtorsCount'] ?? 0}'],
                ['Total deuda', '${summary['totalDebt'] ?? 0}'],
                ['Pagos recibidos hoy', '${summary['paymentsToday'] ?? 0}'],
                ['Productos vendidos (u)', '${summary['soldUnits'] ?? 0}'],
                ['Stock bajo', '${summary['lowStockProducts'] ?? 0}'],
              ],
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/reporte_resumen_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(path).writeAsBytes(await doc.save(), flush: true);
      await Printing.layoutPdf(onLayout: (_) => doc.save(), name: 'reporte_resumen.pdf');
      await Share.shareXFiles([XFile(path)], subject: 'Reporte resumen', text: 'Reporte generado desde la app');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.summary(query),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;
        return ListView(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metric('Ventas día', data['salesToday']),
                _metric('Ventas mes', data['salesMonth']),
                _metric('Ganancia estimada', data['estimatedProfit']),
                _metric('Pedidos', data['ordersCount']),
                _metric('Ticket promedio', data['avgTicket']),
                _metric('Clientes con deuda', data['debtorsCount']),
                _metric('Total deuda', data['totalDebt']),
                _metric('Pagos recibidos', data['paymentsToday']),
                _metric('Productos vendidos', data['soldUnits']),
                _metric('Stock bajo', data['lowStockProducts']),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _metric(String title, dynamic value) => SizedBox(
        width: 170,
        child: Card(child: Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 8), Text('${value ?? 0}', style: const TextStyle(fontSize: 20))]))),
      );
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final totals = snapshot.data!['totals'] as Map<String, dynamic>? ?? {};
        final byDay = (snapshot.data!['byDay'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          children: [
            ListTile(title: const Text('Ventas totales'), trailing: Text('${totals['sales'] ?? 0}')),
            ListTile(title: const Text('Pedidos'), trailing: Text('${totals['orders'] ?? 0}')),
            ListTile(title: const Text('Ticket promedio'), trailing: Text('${totals['avgTicket'] ?? 0}')),
            const SizedBox(height: 8),
            const Text('Ventas por día', style: TextStyle(fontWeight: FontWeight.w700)),
            SimpleBarChart(values: byDay.map((e) => (e['sales'] as num?)?.toDouble() ?? 0).toList()),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final totals = snapshot.data!['totals'] as Map<String, dynamic>? ?? {};
        final byCategory = (snapshot.data!['byCategory'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          children: [
            ListTile(title: const Text('Costo total vendido'), trailing: Text('${totals['costTotal'] ?? 0}')),
            ListTile(title: const Text('Venta total'), trailing: Text('${totals['salesTotal'] ?? 0}')),
            ListTile(title: const Text('Ganancia bruta'), trailing: Text('${totals['grossProfit'] ?? 0}')),
            ListTile(title: const Text('Margen promedio %'), trailing: Text('${totals['avgMargin'] ?? 0}')),
            const Divider(),
            const Text('Ganancia por categoría', style: TextStyle(fontWeight: FontWeight.w700)),
            ...byCategory.take(8).map((e) => ListTile(title: Text('${e['category']}'), trailing: Text('${e['profit']}'))),
          ],
        );
      },
    );
  }
}

class _TopClientsTab extends StatelessWidget {
  const _TopClientsTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: repo.topClients(query),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final topBuyers = (snapshot.data!['topBuyers'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final debtors = (snapshot.data!['topDebtors'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final inactive = (snapshot.data!['inactive'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          children: [
            const Text('Clientes que más compran', style: TextStyle(fontWeight: FontWeight.w700)),
            ...topBuyers.take(10).map((e) => ListTile(title: Text('${e['businessName']}'), subtitle: Text('Pedidos: ${e['ordersCount']} · Última: ${e['lastPurchase'] ?? '-'}'), trailing: Text('${e['totalBought']}'))),
            const Divider(),
            const Text('Clientes con más deuda', style: TextStyle(fontWeight: FontWeight.w700)),
            ...debtors.take(10).map((e) => ListTile(title: Text('${e['businessName']}'), subtitle: Text('${e['zone'] ?? '-'}'), trailing: Text('${e['currentBalance']}'))),
            const Divider(),
            const Text('Inactivos / sin compra reciente', style: TextStyle(fontWeight: FontWeight.w700)),
            ...inactive.take(10).map((e) => ListTile(title: Text('${e['businessName']}'), subtitle: Text('Última: ${e['lastPurchase'] ?? 'Sin compras'}'))),
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final top = (snapshot.data!['topByQuantity'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final lowRotation = (snapshot.data!['lowRotation'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        final noRecent = (snapshot.data!['noRecentSales'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        return ListView(
          children: [
            const Text('Más vendidos (cantidad)', style: TextStyle(fontWeight: FontWeight.w700)),
            ...top.take(10).map((e) => ListTile(title: Text('${e['productName']}'), subtitle: Text('Fact: ${e['revenue']} · Gan: ${e['profit']}'), trailing: Text('${e['quantity']}'))),
            const Divider(),
            const Text('Baja rotación', style: TextStyle(fontWeight: FontWeight.w700)),
            ...lowRotation.take(10).map((e) => ListTile(title: Text('${e['productName']}'), trailing: Text('${e['quantity']}'))),
            const Divider(),
            const Text('Sin ventas recientes', style: TextStyle(fontWeight: FontWeight.w700)),
            ...noRecent.take(10).map((e) => ListTile(title: Text('${e['productName']}'), subtitle: Text('Última: ${e['lastSale'] ?? 'Sin ventas'}'))),
          ],
        );
      },
    );
  }
}

class _DebtorsTab extends StatelessWidget {
  const _DebtorsTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.debtors(query),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final debtors = snapshot.data!;
        if (debtors.isEmpty) return const Center(child: Text('Sin deudores en el período actual.'));
        return ListView(
          children: debtors
              .map((e) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: Text('${e['businessName']}'),
                      subtitle: Text('Zona: ${e['zone'] ?? '-'} · Límite: ${e['creditLimit']}'),
                      trailing: Text('${e['balance']}'),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _StockTab extends StatelessWidget {
  const _StockTab({required this.repo, required this.query});
  final ReportsRepository repo;
  final Map<String, dynamic> query;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: repo.stock(query),
      builder: (_, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!;
        if (products.isEmpty) return const Center(child: Text('No hay productos en stock crítico.'));
        return ListView(
          children: products
              .map((e) => Card(
                    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
                    child: ListTile(
                      title: Text('${e['productName']}'),
                      subtitle: Text('Stock: ${e['stockCurrent']} / Mín: ${e['stockMinimum']}'),
                      trailing: Text('Falta ${e['shortage']}'),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}
