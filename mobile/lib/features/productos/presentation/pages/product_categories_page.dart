import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';

class ProductCategoriesPage extends StatefulWidget {
  const ProductCategoriesPage({required this.canManage, super.key});

  final bool canManage;

  @override
  State<ProductCategoriesPage> createState() => _ProductCategoriesPageState();
}

class _ProductCategoriesPageState extends State<ProductCategoriesPage> {
  bool _loading = true;
  List<ProductCategory> _items = [];
  bool? _filterActive;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await context.read<ProductsCubit>().listCategories(includeInactive: true);
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items.where((c) {
      if (_filterActive == null) return true;
      return c.isActive == _filterActive;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías de productos')),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Crear categoría'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: visible.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(label: const Text('Todos'), selected: _filterActive == null, onSelected: (_) => setState(() => _filterActive = null)),
                        ChoiceChip(label: const Text('Activos'), selected: _filterActive == true, onSelected: (_) => setState(() => _filterActive = true)),
                        ChoiceChip(label: const Text('Inactivos'), selected: _filterActive == false, onSelected: (_) => setState(() => _filterActive = false)),
                      ],
                    ),
                  );
                }
                final c = visible[index - 1];
                return Card(
                  child: ListTile(
                    title: Text(c.name),
                    subtitle: Text(c.description ?? ''),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.isActive ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(c.isActive ? 'Activo' : 'Inactivo'),
                    ),
                    trailing: widget.canManage
                        ? Wrap(
                            spacing: 8,
                            children: [
                              IconButton(onPressed: () => _openEditor(category: c), icon: const Icon(Icons.edit)),
                              if (c.isActive)
                                IconButton(
                                  onPressed: () => _toggleStatus(c, activate: false),
                                  icon: const Icon(Icons.block),
                                )
                              else
                                IconButton(onPressed: () => _toggleStatus(c, activate: true), icon: const Icon(Icons.check_circle_outline)),
                              IconButton(onPressed: () => _deleteOrMove(c), icon: const Icon(Icons.delete_outline)),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _openEditor({ProductCategory? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nombre')),
              const SizedBox(height: 8),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descripción (opcional)')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  await context.read<ProductsCubit>().saveCategory(
                    id: category?.id,
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty ? null : descriptionController.text.trim(),
                  );
                  if (mounted) Navigator.pop(context, true);
                },
                child: const Text('Guardar categoría'),
              ),
            ],
          ),
        );
      },
    );

    if (saved == true) {
      await _load();
    }
  }

  Future<void> _deleteOrMove(ProductCategory category) async {
    try {
      await context.read<ProductsCubit>().deleteCategory(category.id);
      await _load();
    } catch (_) {
      final alternatives = _items.where((c) => c.id != category.id && c.isActive).toList();
      if (alternatives.isEmpty || !mounted) return;

      String? destination = alternatives.first.id;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Mover productos a otra categoría'),
          content: StatefulBuilder(
            builder: (context, setModal) => DropdownButtonFormField<String>(
              isExpanded: true,
              value: destination,
              items: alternatives.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (v) => setModal(() => destination = v),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mover y eliminar')),
          ],
        ),
      );

      if (proceed == true && destination != null) {
        await context.read<ProductsCubit>().moveCategoryProducts(id: category.id, categoryId: destination!);
        await context.read<ProductsCubit>().deleteCategory(category.id);
        await _load();
      }
    }
  }

  Future<void> _toggleStatus(ProductCategory category, {required bool activate}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(activate ? 'Activar categoría' : 'Desactivar categoría'),
        content: Text(activate ? '¿Querés activar esta categoría?' : '¿Querés desactivar esta categoría?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(activate ? 'Activar' : 'Desactivar')),
        ],
      ),
    );
    if (ok != true) return;
    if (activate) {
      await context.read<ProductsCubit>().activateCategory(category.id);
    } else {
      await context.read<ProductsCubit>().deactivateCategory(category.id);
    }
    await _load();
  }
}
