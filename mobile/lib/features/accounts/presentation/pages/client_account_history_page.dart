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
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _items = await context.read<AccountsRepository>().movements(
            widget.clientId,
            type: _type,
            dateFrom: _dateFrom == null ? null : _yyyyMmDd(_dateFrom!),
            dateTo: _dateTo == null ? null : _yyyyMmDd(_dateTo!),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Historial · ${widget.clientName}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFrom: true),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_dateFrom == null ? 'Desde' : _displayDate(_dateFrom!)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(isFrom: false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_dateTo == null ? 'Hasta' : _displayDate(_dateTo!)),
                  ),
                ),
                IconButton(
                  tooltip: 'Limpiar fechas',
                  onPressed: () {
                    setState(() {
                      _dateFrom = null;
                      _dateTo = null;
                    });
                    _load();
                  },
                  icon: const Icon(Icons.clear_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Sin movimientos para este filtro.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          itemBuilder: (_, i) {
                            final m = _items[i];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _movementColor(m.movementType).withValues(alpha: 0.16),
                                  child: Icon(Icons.receipt_long_rounded, color: _movementColor(m.movementType)),
                                ),
                                title: Text('${_labelType(m.movementType)} · ${m.amount.toStringAsFixed(2)}'),
                                subtitle: Text(
                                  '${_displayDateTime(m.createdAt)}\nRef: ${m.referenceType ?? '-'} ${m.referenceId ?? ''}',
                                ),
                                isThreeLine: true,
                                trailing: Text(
                                  'Saldo\n${m.newBalance.toStringAsFixed(2)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_dateFrom ?? now) : (_dateTo ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );

    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
      } else {
        _dateTo = picked;
      }
    });
    _load();
  }

  String _displayDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _displayDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${_displayDate(local)} $hh:$mm';
  }

  String _yyyyMmDd(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _labelType(String raw) {
    switch (raw) {
      case 'deuda':
        return 'Deuda';
      case 'pago':
        return 'Pago';
      case 'ajuste':
        return 'Ajuste';
      default:
        return raw;
    }
  }

  Color _movementColor(String raw) {
    if (raw == 'pago') return Colors.green.shade700;
    if (raw == 'deuda') return Colors.red.shade700;
    return Colors.amber.shade800;
  }
}
