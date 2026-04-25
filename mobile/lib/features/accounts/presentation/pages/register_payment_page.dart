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
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _method = 'efectivo';
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente', style: Theme.of(context).textTheme.labelMedium),
                          Text(widget.clientName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monto', prefixIcon: Icon(Icons.attach_money_rounded)),
              validator: (value) {
                final amount = double.tryParse(value ?? '') ?? 0;
                return amount <= 0 ? 'Ingresá un monto válido' : null;
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _method,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Método de pago', prefixIcon: Icon(Icons.payments_outlined)),
              items: const [
                DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                DropdownMenuItem(value: 'mercado_pago', child: Text('Mercado Pago')),
                DropdownMenuItem(value: 'otro', child: Text('Otro')),
              ],
              onChanged: (v) => setState(() => _method = v ?? 'efectivo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Observaciones', alignLabelWithHint: true),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(_saving ? 'Guardando...' : 'Confirmar pago'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.parse(_amount.text);
    setState(() => _saving = true);
    try {
      await context.read<AccountsRepository>().registerPayment(
            clientId: widget.clientId,
            amount: amount,
            paymentMethod: _method,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pago registrado con éxito.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}
