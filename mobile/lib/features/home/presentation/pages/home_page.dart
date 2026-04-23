import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String path = '/home';
  static const String name = 'home';

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);
    final role = session?.user.role ?? 'sin rol';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel principal'),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${session?.user.fullName ?? 'usuario'}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Rol activo: $role', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            _RolePermissions(role: role),
          ],
        ),
      ),
    );
  }
}

class _RolePermissions extends StatelessWidget {
  const _RolePermissions({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final items = switch (role) {
      'admin' => ['Acceso total a módulos operativos y administrativos.'],
      'vendedor' => ['Ver clientes', 'Ver productos', 'Ver pedidos', 'Crear pedidos'],
      'repartidor' => ['Ver repartos asignados', 'Ver rutas asignadas', 'Ver entregas asignadas'],
      _ => ['Sin permisos asignados'],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Permisos de operación'),
            const SizedBox(height: 10),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(item)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
