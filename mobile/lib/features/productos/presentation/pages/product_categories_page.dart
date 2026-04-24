import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/product_model.dart';
import '../cubit/products_cubit.dart';

class ProductCategoriesPage extends StatefulWidget {
  const ProductCategoriesPage({super.key});

  @override
  State<ProductCategoriesPage> createState() => _ProductCategoriesPageState();
}

class _ProductCategoriesPageState extends State<ProductCategoriesPage> {
  bool _loading = true;
  List<ProductCategory> _items = [];

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
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías de productos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Crear categoría'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final c = _items[index];
                return Card(
                  child: ListTile(
                    title: Text(c.name),
                    subtitle: Text(c.description ?? (c.isActive ? 'Activa' : 'Inactiva')),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(onPressed: () => _openEditor(category: c), icon: const Icon(Icons.edit)),
                        if (c.isActive)
                          IconButton(
                            onPressed: () async {
                              await context.read<ProductsCubit>().deactivateCategory(c.id);
                              await _load();
                            },
                            icon: const Icon(Icons.block),
                          ),
                      ],
                    ),
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
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
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
}
