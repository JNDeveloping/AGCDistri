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

  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().load();
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
                if (saved == true && mounted) {
                  await context.read<OrdersCubit>().load();
                }
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nuevo pedido'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: context.read<OrdersCubit>().onSearch,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar por número de pedido'),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Todos'), selected: context.watch<OrdersCubit>().state.statusFilter == null, onSelected: (_) => context.read<OrdersCubit>().setStatusFilter(null)),
              ChoiceChip(label: const Text('Pendiente'), selected: context.watch<OrdersCubit>().state.statusFilter == 'pendiente', onSelected: (_) => context.read<OrdersCubit>().setStatusFilter('pendiente')),
              ChoiceChip(label: const Text('En reparto'), selected: context.watch<OrdersCubit>().state.statusFilter == 'en_reparto', onSelected: (_) => context.read<OrdersCubit>().setStatusFilter('en_reparto')),
              ChoiceChip(label: const Text('Entregado'), selected: context.watch<OrdersCubit>().state.statusFilter == 'entregado', onSelected: (_) => context.read<OrdersCubit>().setStatusFilter('entregado')),
            ],
          ),
          Expanded(
            child: BlocBuilder<OrdersCubit, OrdersState>(builder: (_, state) {
              if (state.status == OrdersStatus.loading && state.items.isEmpty) return const Center(child: CircularProgressIndicator());
              if (state.status == OrdersStatus.failure) return Center(child: Text(state.errorMessage ?? 'No se pudo cargar pedidos'));
              if (state.items.isEmpty) return const Center(child: Text('Sin pedidos.'));
              return ListView.builder(
                itemCount: state.items.length,
                itemBuilder: (_, i) {
                  final o = state.items[i];
                  return ListTile(
                    title: Text('Pedido #${o.orderNumber} · ${o.clientName}'),
                    subtitle: Text('${o.status} · ${o.total.toStringAsFixed(2)}'),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: o.id))),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}
