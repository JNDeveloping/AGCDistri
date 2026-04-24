import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/models/order_model.dart';
import '../cubit/orders_cubit.dart';
import 'order_form_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({required this.orderId, super.key});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<OrderModel> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<OrdersCubit>().getById(widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthCubit cubit) => cubit.state.session?.user.role ?? 'vendedor');
    final canManage = role == 'admin' || role == 'vendedor';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de pedido')),
      body: FutureBuilder<OrderModel>(
        future: _future,
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData) return const Center(child: Text('No se pudo cargar el pedido.'));
          final o = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text('Pedido #${o.orderNumber}', style: Theme.of(context).textTheme.titleLarge),
              Text('Cliente: ${o.clientName}'),
              Text('Vendedor: ${o.sellerName}'),
              Text('Estado: ${o.status}'),
              Text('Condición de pago: ${o.paymentTerms ?? '-'}'),
              Text('Dirección entrega: ${o.deliveryAddress ?? '-'}'),
              if (canManage && o.status == 'pendiente')
                Row(children: [
                  OutlinedButton(onPressed: () async {
                    final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => OrderFormPage(orderId: o.id)));
                    if (changed == true && mounted) setState(() => _future = context.read<OrdersCubit>().getById(widget.orderId));
                  }, child: const Text('Editar')),
                  const SizedBox(width: 8),
                  TextButton(onPressed: () async {
                    await context.read<OrdersCubit>().cancel(o.id);
                    if (mounted) setState(() => _future = context.read<OrdersCubit>().getById(widget.orderId));
                  }, child: const Text('Cancelar')),
                ]),
              if (canManage && o.status != 'entregado' && o.status != 'cancelado')
                Wrap(spacing: 8, children: [
                  for (final status in const ['confirmado','preparado','en_reparto','entregado'])
                    OutlinedButton(
                      onPressed: () async {
                        await context.read<OrdersCubit>().changeStatus(o.id, status);
                        if (mounted) setState(() => _future = context.read<OrdersCubit>().getById(widget.orderId));
                      },
                      child: Text(status),
                    ),
                ]),
              const SizedBox(height: 8),
              ...o.items.map((i) => ListTile(
                    title: Text(i.productName),
                    subtitle: Text('${i.quantity} x ${i.unitPrice.toStringAsFixed(2)}'),
                    trailing: Text(i.subtotal.toStringAsFixed(2)),
                  )),
              const Divider(),
              Text('Subtotal: ${o.subtotal.toStringAsFixed(2)}'),
              Text('Descuento: ${o.discountTotal.toStringAsFixed(2)}'),
              Text('Impuestos: ${o.taxTotal.toStringAsFixed(2)}'),
              Text('Total: ${o.total.toStringAsFixed(2)}'),
              Text('Margen estimado: ${o.estimatedMargin.toStringAsFixed(2)}'),
            ],
          );
        },
      ),
    );
  }
}
