import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../accounts/presentation/pages/accounts_overview_page.dart';
import '../../../clientes/presentation/pages/clientes_page.dart';
import '../../../pedidos/presentation/pages/pedidos_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
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
                  _metricCard(context, 'Clientes totales', stats.totalClients.toString(), Icons.groups_rounded),
                  _metricCard(context, 'Clientes activos', stats.activeClients.toString(), Icons.verified_user_rounded),
                  _metricCard(context, 'Productos totales', stats.totalProducts.toString(), Icons.inventory_2_rounded),
                  _metricCard(context, 'Productos activos', stats.activeProducts.toString(), Icons.check_circle_rounded),
                  _metricCard(context, 'Stock bajo', stats.lowStockProducts.toString(), Icons.warning_amber_rounded, warning: true),
                ],
              ),
              const SizedBox(height: 18),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Acciones rápidas', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => context.go(PedidosPage.path),
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: const Text('Nuevo pedido'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () => context.go(ClientesPage.path),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Nuevo cliente'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go(AccountsOverviewPage.path),
                            icon: const Icon(Icons.payments_rounded),
                            label: const Text('Registrar pago'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _recentSection(
                context,
                title: 'Últimos clientes',
                icon: Icons.groups_2_rounded,
                items: stats.recentClients,
                titleKey: 'businessName',
                subtitleKey: 'internalCode',
              ),
              const SizedBox(height: 12),
              _recentSection(
                context,
                title: 'Últimos productos',
                icon: Icons.inventory_rounded,
                items: stats.recentProducts,
                titleKey: 'name',
                subtitleKey: 'internalCode',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricCard(BuildContext context, String title, String value, IconData icon, {bool warning = false}) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 170,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        color: warning ? colors.errorContainer : colors.primaryContainer.withOpacity(0.45),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: warning ? colors.onErrorContainer : colors.primary),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: warning ? colors.onErrorContainer : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required String titleKey,
    required String subtitleKey,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Sin datos recientes.'),
              )
            else
              ...items.map(
                (item) => ListTile(
                  dense: true,
                  title: Text(item[titleKey]?.toString() ?? '-'),
                  subtitle: Text(item[subtitleKey]?.toString() ?? '-'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
