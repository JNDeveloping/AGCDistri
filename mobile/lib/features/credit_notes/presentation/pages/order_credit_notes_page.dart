import 'package:flutter/material.dart';

import '../../../pedidos/domain/models/order_model.dart';
import '../../data/repositories/credit_note_repository.dart';
import '../../domain/models/credit_note_model.dart';
import 'credit_note_detail_page.dart';
import 'credit_note_form_page.dart';

class OrderCreditNotesPage extends StatefulWidget {
  const OrderCreditNotesPage({
    required this.order,
    required this.repository,
    super.key,
  });

  final OrderModel order;
  final CreditNoteRepository repository;

  @override
  State<OrderCreditNotesPage> createState() => _OrderCreditNotesPageState();
}

class _OrderCreditNotesPageState extends State<OrderCreditNotesPage> {
  late Future<List<CreditNoteModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.listByOrder(widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notas de crédito · Pedido #${widget.order.orderNumber}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Nueva nota'),
      ),
      body: FutureBuilder<List<CreditNoteModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString().replaceFirst('Exception: ', '')));
          }
          final notes = snapshot.data ?? const [];
          if (notes.isEmpty) {
            return const Center(child: Text('No hay notas de crédito para este pedido.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final n = notes[index];
              return Card(
                child: ListTile(
                  title: Text('Nota #${n.number} · ${n.totalAmount.toStringAsFixed(2)}'),
                  subtitle: Text('${n.reason}\n${n.createdAt?.toLocal().toString().split('.').first ?? '-'}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreditNoteDetailPage(
                          creditNoteId: n.id,
                          repository: widget.repository,
                          clientPhone: widget.order.clientPhone,
                          orderNumber: widget.order.orderNumber,
                        ),
                      ),
                    );
                    if (mounted) {
                      setState(() => _future = widget.repository.listByOrder(widget.order.id));
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreditNoteFormPage(order: widget.order, repository: widget.repository),
      ),
    );

    if (created == true && mounted) {
      setState(() => _future = widget.repository.listByOrder(widget.order.id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota de crédito creada y lista actualizada.')));
    }
  }
}
