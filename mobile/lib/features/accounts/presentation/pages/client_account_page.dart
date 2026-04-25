import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/accounts_repository.dart';
import '../../domain/models/account_models.dart';
import 'client_account_history_page.dart';
import 'register_payment_page.dart';

class ClientAccountPage extends StatefulWidget {
  const ClientAccountPage({required this.clientId, required this.clientName, super.key});

  final String clientId;
  final String clientName;

  @override
  State<ClientAccountPage> createState() => _ClientAccountPageState();
}

class _ClientAccountPageState extends State<ClientAccountPage> {
  ClientAccount? _account;
  bool _loading = true;

  AccountsRepository get _repo => context.read<AccountsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final account = await _repo.account(widget.clientId);
      if (mounted) {
        setState(() => _account = account);
      }
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
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final isAdmin = role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta corriente')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _account == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded),
                        const SizedBox(height: 8),
                        const Text('No se pudo cargar la cuenta.'),
                        const SizedBox(height: 12),
                        FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(14),
                    children: [
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primaryContainer,
                                Theme.of(context).colorScheme.secondaryContainer,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.clientName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text('Saldo actual', style: Theme.of(context).textTheme.labelLarge),
                              Text(
                                _account!.currentBalance.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, height: 1),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(
                                    label: Text(_account!.status == 'con_deuda' ? 'Con deuda' : 'Al día'),
                                    backgroundColor: _account!.status == 'con_deuda' ? Colors.red.shade100 : Colors.green.shade100,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Límite: ${_account!.creditLimit.toStringAsFixed(2)}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              final changed = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegisterPaymentPage(clientId: widget.clientId, clientName: widget.clientName),
                                ),
                              );
                              if (changed == true) {
                                _load();
                              }
                            },
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Registrar pago'),
                          ),
                          if (isAdmin)
                            OutlinedButton.icon(
                              onPressed: _adjustBalance,
                              icon: const Icon(Icons.tune),
                              label: const Text('Ajustar saldo'),
                            ),
                          TextButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientAccountHistoryPage(clientId: widget.clientId, clientName: widget.clientName),
                              ),
                            ),
                            icon: const Icon(Icons.history_rounded),
                            label: const Text('Ver historial completo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Últimos movimientos', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_account!.recentMovements.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(14),
                            child: Text('Sin movimientos recientes.'),
                          ),
                        ),
                      ..._account!.recentMovements.map(
                        (m) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _movementColor(m.movementType).withValues(alpha: 0.15),
                              child: Icon(Icons.receipt_long_rounded, color: _movementColor(m.movementType)),
                            ),
                            title: Text('${_labelType(m.movementType)} · ${m.amount.toStringAsFixed(2)}'),
                            subtitle: Text('${_formatDateTime(m.createdAt)} · ${m.description}\nRef: ${m.referenceType ?? '-'}'),
                            isThreeLine: true,
                            trailing: Text(
                              'Saldo\n${m.newBalance.toStringAsFixed(2)}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _adjustBalance() async {
    final amount = TextEditingController();
    final description = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajustar saldo'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto'),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) == 0 ? 'Ingresá un monto distinto de 0' : null,
              ),
              TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Descripción'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresá una descripción' : null,
              ),
              TextField(controller: notes, decoration: const InputDecoration(labelText: 'Observaciones')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _repo.adjustBalance(
        clientId: widget.clientId,
        amount: double.tryParse(amount.text) ?? 0,
        description: description.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajuste registrado.')));
      }
      _load();
    }
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final local = value.toLocal();
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${local.year} $hh:$min';
  }

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
