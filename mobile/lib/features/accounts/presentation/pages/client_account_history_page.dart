import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/accounts_repository.dart';
import '../../domain/models/account_models.dart';

class ClientAccountHistoryPage extends StatefulWidget {
  const ClientAccountHistoryPage({required this.clientId, required this.clientName, super.key});

  final String clientId;
  final String clientName;

  @override
  State<ClientAccountHistoryPage> createState() => _ClientAccountHistoryPageState();
}

class _ClientAccountHistoryPageState extends State<ClientAccountHistoryPage> {
  List<AccountMovement> _items = const [];
  bool _loading = true;
  String? _type;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await context.read<AccountsRepository>().movements(widget.clientId, type: _type);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial · ${widget.clientName}')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String?>(
            value: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Filtrar por tipo'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Todos')),
              DropdownMenuItem(value: 'deuda', child: Text('Deuda')),
              DropdownMenuItem(value: 'pago', child: Text('Pago')),
              DropdownMenuItem(value: 'ajuste', child: Text('Ajuste')),
            ],
            onChanged: (v) {
              setState(() => _type = v);
              _load();
            },
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? const Center(child: Text('Sin movimientos para este filtro.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final m = _items[i];
                        return Card(
                          child: ListTile(
                            title: Text('${m.movementType} · ${m.amount.toStringAsFixed(2)}'),
                            subtitle: Text('${m.description}\n${m.createdAt?.toLocal().toString().split('.').first ?? '-'} · Ref: ${m.referenceType ?? '-'}'),
                            isThreeLine: true,
                            trailing: Text('Saldo: ${m.newBalance.toStringAsFixed(2)}'),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
