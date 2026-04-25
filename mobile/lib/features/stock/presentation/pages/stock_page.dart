import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/stock_cubit.dart';
import '../cubit/stock_state.dart';
import '../widgets/stock_product_card.dart';
import 'stock_product_detail_page.dart';

class StockPage extends StatefulWidget {
  const StockPage({super.key});

  static const path = '/stock';
  static const name = 'stock';

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<StockCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      bottomNavigationBar: AppBottomNavBar(currentRoute: StockPage.path, role: role),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: context.read<StockCubit>().onSearch,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Buscar producto, código o barras'),
            ),
          ),
          Wrap(spacing: 8, children: [
            _chip('Todos', 'all'),
            _chip('Stock bajo', 'low'),
            _chip('Sin stock', 'out'),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<StockCubit, StockState>(
              builder: (_, state) {
                if (state.status == StockStatus.loading && state.items.isEmpty) return const Center(child: CircularProgressIndicator());
                if (state.status == StockStatus.failure) return Center(child: Text(state.error ?? 'Error de stock'));
                if (state.items.isEmpty) return const Center(child: Text('No hay productos para mostrar.'));
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.items.length,
                  itemBuilder: (_, i) => StockProductCard(
                    item: state.items[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockProductDetailPage(productId: state.items[i].productId))),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = context.watch<StockCubit>().state.filter == value;
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => context.read<StockCubit>().setFilter(value));
  }
}
