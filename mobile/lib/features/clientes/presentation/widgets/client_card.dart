import 'package:flutter/material.dart';

import '../../domain/models/client_model.dart';
import '../utils/whatsapp_utils.dart';

class ClientCard extends StatelessWidget {
  const ClientCard({
    required this.client,
    required this.onTap,
    required this.onEdit,
    required this.onDeactivate,
    required this.onDelete,
    required this.onActivate,
    this.canEdit = true,
    super.key,
  });

  final ClientModel client;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onDelete;
  final VoidCallback onActivate;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final isInactive = !client.isActive;
    final colors = Theme.of(context).colorScheme;
    final whatsappUrl = buildWhatsappUrl(client.phone);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      client.businessName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (isInactive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: BorderRadius.circular(10)),
                      child: Text('Inactivo', style: TextStyle(color: colors.onErrorContainer, fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text('${client.internalCode} · ${client.city}, ${client.province}'),
              Text('Teléfono: ${client.phone}'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: Text('Saldo: ${client.currentBalance.toStringAsFixed(2)}')),
                  Expanded(child: Text('Límite: ${client.creditLimit.toStringAsFixed(2)}')),
                  if (whatsappUrl != null)
                    IconButton(
                      onPressed: () async {
                        final ok = await openClientWhatsapp(client.phone);
                        if (context.mounted && !ok) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp.')));
                        }
                      },
                      icon: const Icon(Icons.chat),
                      tooltip: 'WhatsApp',
                    ),
                ],
              ),
              if (canEdit) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    OutlinedButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_rounded), label: const Text('Editar')),
                    const SizedBox(width: 10),
                    if (client.isActive)
                      TextButton.icon(onPressed: onDeactivate, icon: const Icon(Icons.block_rounded), label: const Text('Desactivar'))
                    else
                      TextButton.icon(onPressed: onActivate, icon: const Icon(Icons.check_circle_outline_rounded), label: const Text('Activar')),
                    const SizedBox(width: 8),
                    TextButton.icon(onPressed: onDelete, icon: const Icon(Icons.delete_outline_rounded), label: const Text('Eliminar')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
