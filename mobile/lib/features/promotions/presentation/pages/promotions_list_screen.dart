import 'package:flutter/material.dart';

import '../../data/repositories/promotion_repository.dart';
import '../../domain/models/promotion_model.dart';
import 'promotion_detail_screen.dart';
import 'promotion_form_screen.dart';

class PromotionsListScreen extends StatefulWidget {
  const PromotionsListScreen({required this.repository, super.key});

  static const path = '/profile/promotions';
  static const name = 'promotions';

  final PromotionRepository repository;

  @override
  State<PromotionsListScreen> createState() => _PromotionsListScreenState();
}

class _PromotionsListScreenState extends State<PromotionsListScreen> {
  final _queryController = TextEditingController();

  bool? _active;
  String? _type;
  List<PromotionModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await widget.repository.list(
        q: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
        isActive: _active,
        type: _type,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm({String? promotionId}) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PromotionFormScreen(
          repository: widget.repository,
          promotionId: promotionId,
        ),
      ),
    );
    if (updated == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promociones')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        label: const Text('Nueva'),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar por nombre',
                    suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<bool?>(
                        value: _active,
                        decoration: const InputDecoration(labelText: 'Estado'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todas')),
                          DropdownMenuItem(value: true, child: Text('Activas')),
                          DropdownMenuItem(value: false, child: Text('Inactivas')),
                        ],
                        onChanged: (value) {
                          _active = value;
                          _load();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Todos')),
                          DropdownMenuItem(value: 'quantity_discount', child: Text('Por unidades')),
                          DropdownMenuItem(value: 'bulk_discount', child: Text('Por bultos')),
                          DropdownMenuItem(value: 'tiered_discount', child: Text('Escalonada')),
                          DropdownMenuItem(value: 'combo', child: Text('Combo')),
                          DropdownMenuItem(value: 'x_for_y', child: Text('Llevá X pagá Y')),
                          DropdownMenuItem(value: 'order_total_discount', child: Text('Por monto total')),
                          DropdownMenuItem(value: 'target_discount', child: Text('Por cliente/zona')),
                          DropdownMenuItem(value: 'stock_discount', child: Text('Liquidación')),
                        ],
                        onChanged: (value) {
                          _type = value;
                          _load();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, index) {
                      final promotion = _items[index];
                      return Card(
                        child: ListTile(
                          title: Text(promotion.name),
                          subtitle: Text('${promotion.type} · prioridad ${promotion.priority}'),
                          trailing: Switch(
                            value: promotion.isActive,
                            onChanged: (_) {
                              widget.repository.toggle(promotion.id).then((_) => _load());
                            },
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PromotionDetailScreen(
                                  repository: widget.repository,
                                  promotionId: promotion.id,
                                ),
                              ),
                            );
                            _load();
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
}
