import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../clientes/data/repositories/client_repository.dart';
import '../../data/repositories/accounts_repository.dart';
import '../cubit/accounts_overview_cubit.dart';
import '../cubit/accounts_overview_state.dart';
import 'client_account_page.dart';

class AccountsOverviewPage extends StatelessWidget {
  const AccountsOverviewPage({super.key});

  static const String path = '/cuentas-corrientes';
  static const String name = 'cuentas-corrientes';

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');

    return BlocProvider(
      create: (_) => AccountsOverviewCubit(
        accountsRepository: context.read<AccountsRepository>(),
        clientRepository: context.read<ClientRepository>(),
      )..load(),
      child: _AccountsOverviewView(role: role),
    );
  }
}

class _AccountsOverviewView extends StatefulWidget {
  const _AccountsOverviewView({required this.role});
  final String role;

  @override
  State<_AccountsOverviewView> createState() => _AccountsOverviewViewState();
}

class _AccountsOverviewViewState extends State<_AccountsOverviewView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas Corrientes')),
      bottomNavigationBar: AppBottomNavBar(currentRoute: AccountsOverviewPage.path, role: widget.role),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: context.read<AccountsOverviewCubit>().onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Buscar cliente por nombre, código, teléfono o localidad',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 8),
                BlocBuilder<AccountsOverviewCubit, AccountsOverviewState>(
                  builder: (context, state) => Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: state.filter == AccountsOverviewFilter.all,
                        onSelected: (_) => context.read<AccountsOverviewCubit>().setFilter(AccountsOverviewFilter.all),
                      ),
                      ChoiceChip(
                        label: const Text('Con deuda'),
                        selected: state.filter == AccountsOverviewFilter.withDebt,
                        onSelected: (_) => context.read<AccountsOverviewCubit>().setFilter(AccountsOverviewFilter.withDebt),
                      ),
                      ChoiceChip(
                        label: const Text('Al día'),
                        selected: state.filter == AccountsOverviewFilter.upToDate,
                        onSelected: (_) => context.read<AccountsOverviewCubit>().setFilter(AccountsOverviewFilter.upToDate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<AccountsOverviewCubit, AccountsOverviewState>(
              builder: (context, state) {
                if (state.status == AccountsOverviewStatus.loading && state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == AccountsOverviewStatus.failure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 38),
                          const SizedBox(height: 8),
                          Text(state.errorMessage ?? 'No se pudo cargar Cuentas Corrientes.'),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: () => context.read<AccountsOverviewCubit>().load(),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('No hay clientes para este filtro.'),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => context.read<AccountsOverviewCubit>().load(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 84),
                    itemCount: state.items.length,
                    itemBuilder: (_, index) {
                      final item = state.items[index];
                      final balance = item.currentBalance;
                      final hasDebt = balance > 0;
                      final hasFavor = balance < 0;
                      final statusColor = hasDebt ? Colors.red.shade700 : (hasFavor ? Colors.blue.shade700 : Colors.green.shade700);
                      final statusLabel = hasDebt ? 'Debe' : (hasFavor ? 'Saldo a favor' : 'Al día');

                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientAccountPage(
                                  clientId: item.client.id,
                                  clientName: item.client.businessName,
                                ),
                              ),
                            );
                            if (!mounted) return;
                            await context.read<AccountsOverviewCubit>().load();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.client.businessName,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                      ),
                                    ),
                                    Chip(
                                      avatar: Icon(
                                        hasDebt ? Icons.warning_amber_rounded : (hasFavor ? Icons.savings_rounded : Icons.check_circle_rounded),
                                        size: 16,
                                        color: statusColor,
                                      ),
                                      label: Text(statusLabel),
                                      backgroundColor: statusColor.withValues(alpha: 0.12),
                                      side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\$ ${item.currentBalance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 34,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    _metaPill(
                                      icon: Icons.history_rounded,
                                      text: 'Última actividad: ${_formatDateTime(item.lastActivity)}',
                                    ),
                                    _metaPill(
                                      icon: Icons.route_rounded,
                                      text: 'Zona: ${item.client.zoneName ?? item.client.routeZone}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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

  Widget _metaPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$min';
  }
}

