import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/accounts_repository.dart';
import '../../domain/models/account_models.dart';

class PaymentDetailPage extends StatefulWidget {
  const PaymentDetailPage({required this.paymentId, super.key});

  final String paymentId;

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  late Future<ClientPayment> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AccountsRepository>().getPaymentById(widget.paymentId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de pago')),
      body: FutureBuilder<ClientPayment>(
        future: _future,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se pudo cargar el pago.'));
          }

          final payment = snapshot.data!;
          final shortId = payment.id.length > 8 ? payment.id.substring(0, 8) : payment.id;
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pago #$shortId', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text('Cliente: ${payment.clientName}'),
                      Text('Monto: ${payment.amount.toStringAsFixed(2)}'),
                      Text('Método: ${_labelMethod(payment.paymentMethod)}'),
                      Text('Registrado por: ${payment.userName ?? '-'}'),
                      Text('Fecha: ${_formatDateTime(payment.createdAt)}'),
                      if ((payment.notes ?? '').isNotEmpty) Text('Observaciones: ${payment.notes}'),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _labelMethod(String raw) {
    switch (raw) {
      case 'mercado_pago':
        return 'Mercado Pago';
      default:
        return raw[0].toUpperCase() + raw.substring(1).replaceAll('_', ' ');
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
}
