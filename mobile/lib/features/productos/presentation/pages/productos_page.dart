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
  final _scrollController = ScrollController();
  static const _pageSize = 20;
  int _visibleItems = _pageSize;

  @override
  void initState() {
    super.initState();
    context.read<ProductsCubit>().load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset >= (_scrollController.position.maxScrollExtent - 200)) {
      setState(() => _visibleItems += _pageSize);
    }
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
              onChanged: (value) {
                context.read<ProductsCubit>().onSearch(value);
                setState(() => _visibleItems = _pageSize);
              },
              decoration: InputDecoration(
                labelText: 'Buscar por nombre, código, categoría, variante o barras',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          context.read<ProductsCubit>().onSearch('');
                          setState(() => _visibleItems = _pageSize);
                        },
                      ),
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
                if (state.items.isEmpty) {
                  return _EmptyState(
                    icon: Icons.inventory_2_rounded,
                    title: 'No hay productos cargados',
                    subtitle: 'Creá el primer producto para empezar a vender.',
                    actionLabel: canEdit ? 'Nuevo producto' : null,
                    onAction: canEdit ? () => _openForm(context) : null,
                  );
                }
                final visibleCount = state.items.length < _visibleItems ? state.items.length : _visibleItems;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: visibleCount,
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
      await context.read<ProductsCubit>().load(forceRefresh: true);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
