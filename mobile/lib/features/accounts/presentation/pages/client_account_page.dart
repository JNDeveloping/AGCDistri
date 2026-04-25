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
      if (mounted) setState(() => _account = account);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
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
              ? const Center(child: Text('No se pudo cargar la cuenta.'))
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.clientName, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('Saldo actual', style: Theme.of(context).textTheme.labelLarge),
                          Text(_account!.currentBalance.toStringAsFixed(2), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Row(children: [
                            Chip(label: Text(_account!.status == 'con_deuda' ? 'Con deuda' : 'Al día'), backgroundColor: _account!.status == 'con_deuda' ? Colors.red.shade100 : Colors.green.shade100),
                            const SizedBox(width: 8),
                            Text('Límite: ${_account!.creditLimit.toStringAsFixed(2)}'),
                          ]),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final changed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => RegisterPaymentPage(clientId: widget.clientId, clientName: widget.clientName)),
                          );
                          if (changed == true) _load();
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
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ClientAccountHistoryPage(clientId: widget.clientId, clientName: widget.clientName)),
                        ),
                        child: const Text('Ver historial completo'),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text('Últimos movimientos', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (_account!.recentMovements.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Sin movimientos.'))),
                    ..._account!.recentMovements.map((m) => Card(
                          child: ListTile(
                            title: Text('${m.movementType} · ${m.amount.toStringAsFixed(2)}'),
                            subtitle: Text('${m.description}\n${m.createdAt?.toLocal().toString().split('.').first ?? '-'}'),
                            isThreeLine: true,
                            trailing: Text('Saldo: ${m.newBalance.toStringAsFixed(2)}'),
                          ),
                        )),
                  ],
                ),
    );
  }

  Future<void> _adjustBalance() async {
    final amount = TextEditingController();
    final description = TextEditingController();
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajustar saldo'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monto')),
          TextField(controller: description, decoration: const InputDecoration(labelText: 'Descripción')),
          TextField(controller: notes, decoration: const InputDecoration(labelText: 'Observaciones')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aplicar')),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajuste registrado.')));
      _load();
    }
  }
}
