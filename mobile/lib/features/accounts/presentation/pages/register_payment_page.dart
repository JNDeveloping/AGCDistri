import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/accounts_repository.dart';

class RegisterPaymentPage extends StatefulWidget {
  const RegisterPaymentPage({required this.clientId, required this.clientName, super.key});

  final String clientId;
  final String clientName;

  @override
  State<RegisterPaymentPage> createState() => _RegisterPaymentPageState();
}

class _RegisterPaymentPageState extends State<RegisterPaymentPage> {
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _method = 'efectivo';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(widget.clientName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          TextField(controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Monto')),
          DropdownButtonFormField<String>(
            value: _method,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Método de pago'),
            items: const [
              DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
              DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
              DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
              DropdownMenuItem(value: 'mercado_pago', child: Text('Mercado Pago')),
              DropdownMenuItem(value: 'otro', child: Text('Otro')),
            ],
            onChanged: (v) => setState(() => _method = v ?? 'efectivo'),
          ),
          TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Observaciones')),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
            label: Text(_saving ? 'Guardando...' : 'Confirmar pago'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresá un monto válido.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AccountsRepository>().registerPayment(clientId: widget.clientId, amount: amount, paymentMethod: _method, notes: _notes.text.trim().isEmpty ? null : _notes.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado con éxito.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
