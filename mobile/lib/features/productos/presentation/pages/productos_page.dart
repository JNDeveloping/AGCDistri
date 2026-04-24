import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';
import '../cubit/products_state.dart';
import '../widgets/product_card.dart';
import 'product_categories_page.dart';
import 'product_detail_page.dart';
import 'product_form_page.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  static const path = '/productos';
  static const name = 'productos';

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canEdit = role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Productos'),
        actions: [
          if (canEdit)
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductCategoriesPage(canManage: role == 'admin'))),
              icon: const Icon(Icons.category),
              label: const Text('Categorías'),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(currentRoute: ProductosPage.path, role: role),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_box_rounded),
              label: const Text('Nuevo producto'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onChanged: context.read<ProductsCubit>().onSearch,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre, código, marca, categoría o barras',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: context.watch<ProductsCubit>().state.filterActive == null,
                onSelected: (_) => context.read<ProductsCubit>().setActiveFilter(null),
              ),
              ChoiceChip(
                label: const Text('Activos'),
                selected: context.watch<ProductsCubit>().state.filterActive == true,
                onSelected: (_) => context.read<ProductsCubit>().setActiveFilter(true),
              ),
              ChoiceChip(
                label: const Text('Bajo stock'),
                selected: context.watch<ProductsCubit>().state.filterLowStock,
                onSelected: (v) => context.read<ProductsCubit>().setLowStockFilter(v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                if (state.status == ProductsStatus.loading && state.items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == ProductsStatus.failure) {
                  return Center(child: Text(state.errorMessage ?? 'No se pudo cargar productos'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.items.length,
                  itemBuilder: (_, i) {
                    final p = state.items[i];
                    return ProductCard(
                      product: p,
                      canEdit: canEdit,
                      onTap: () => _openDetail(context, p.id),
                      onEdit: () => _openForm(context, product: p),
                      onDeactivate: () => context.read<ProductsCubit>().deactivate(p.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetail(BuildContext context, String id) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailPage(productId: id)));
  }

  Future<void> _openForm(BuildContext context, {ProductModel? product}) async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => ProductFormPage(product: product)));
    if (changed == true && context.mounted) {
      await context.read<ProductsCubit>().load();
    }
  }
}
