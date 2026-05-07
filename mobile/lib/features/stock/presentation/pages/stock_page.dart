import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/stock_cubit.dart';
import '../cubit/stock_state.dart';
import '../widgets/stock_product_card.dart';
import 'stock_product_detail_page.dart';
import 'stock_quick_entry_page.dart';

class StockPage extends StatefulWidget {
  const StockPage({this.initialFilter, super.key});

  static const path = '/stock';
  static const name = 'stock';
  final String? initialFilter;

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<StockCubit>().load();
    if (widget.initialFilter != null && widget.initialFilter != 'all') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<StockCubit>().setFilter(widget.initialFilter!);
      });
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          IconButton(
            tooltip: 'Ingreso rápido de mercadería',
            onPressed: role == 'admin' ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockQuickEntryPage())) : null,
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentRoute: StockPage.path, role: role),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) {
                context.read<StockCubit>().onSearch(v);
                setState(() {});
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                hintText: 'Buscar por nombre, código o barras',
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          context.read<StockCubit>().onSearch('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('Todos', 'all', Icons.inventory_2_outlined),
                  const SizedBox(width: 8),
                  _chip('Stock bajo', 'low', Icons.warning_amber_rounded),
                  const SizedBox(width: 8),
                  _chip('Sin stock', 'out', Icons.remove_shopping_cart_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<StockCubit, StockState>(
              builder: (_, state) {
                if (state.status == StockStatus.loading && state.items.isEmpty) {
                  return _StockSkeletonList();
                }

                if (state.status == StockStatus.failure) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 36),
                          const SizedBox(height: 8),
                          Text(state.error ?? 'No se pudo cargar el stock', textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: context.read<StockCubit>().load,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (state.items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.inbox_outlined, size: 36),
                          SizedBox(height: 8),
                          Text('No hay productos para este filtro.'),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: context.read<StockCubit>().load,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) => StockProductCard(
                      item: state.items[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StockProductDetailPage(productId: state.items[i].productId),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, IconData icon) {
    final selected = context.watch<StockCubit>().state.filter == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: selected,
      onSelected: (_) => context.read<StockCubit>().setFilter(value),
    );
  }
}

class _StockSkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (_, __) => Card(
        elevation: 0,
        child: Container(
          height: 132,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 10),
        ),
      ),
    );
  }
}
