import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentRoute: DashboardPage.path, role: role),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          if (state.status == DashboardStatus.loading || state.status == DashboardStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == DashboardStatus.failure || state.stats == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage ?? 'No se pudieron cargar métricas'),
                  TextButton(onPressed: () => context.read<DashboardCubit>().load(), child: const Text('Reintentar')),
                ],
              ),
            );
          }

          final stats = state.stats!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _metricCard('Clientes totales', stats.totalClients.toString()),
                  _metricCard('Clientes activos', stats.activeClients.toString()),
                  _metricCard('Productos totales', stats.totalProducts.toString()),
                  _metricCard('Productos activos', stats.activeProducts.toString()),
                  _metricCard('Productos bajo stock', stats.lowStockProducts.toString(), warning: true),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Últimos clientes'),
              ...stats.recentClients.map((c) => ListTile(title: Text(c['businessName'] as String), subtitle: Text(c['internalCode'] as String))),
              const SizedBox(height: 12),
              const Text('Últimos productos'),
              ...stats.recentProducts.map((p) => ListTile(title: Text(p['name'] as String), subtitle: Text(p['internalCode'] as String))),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(String title, String value, {bool warning = false}) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: warning ? Colors.red : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
