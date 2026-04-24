import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 20),
        Text(
          'AGC Distribuidora',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Iniciá sesión para gestionar ventas, logística y administración desde una sola app.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
        ),
      ],
    );
  }
}
