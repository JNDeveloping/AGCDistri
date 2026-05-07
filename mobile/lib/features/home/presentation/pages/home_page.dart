import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../clientes/presentation/pages/clientes_page.dart';
import '../../../productos/presentation/pages/productos_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const String path = '/home';
  static const String name = 'home';

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);
    final role = session?.user.role ?? 'sin rol';

    final canManageModules = role == 'admin' || role == 'vendedor' || role == 'repartidor';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 32, fit: BoxFit.contain),
            const SizedBox(width: 10),
            const Text('Panel principal'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<AuthCubit>().logout(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Hola, ${session?.user.fullName ?? 'usuario'}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Rol activo: $role', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.groups_rounded),
              title: const Text('Módulo de Clientes'),
              subtitle: const Text('Gestión comercial y datos para pedidos/rutas/cobranzas'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: canManageModules ? () => context.go(ClientesPage.path) : null,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_rounded),
              title: const Text('Módulo de Productos'),
              subtitle: const Text('Catálogo con stock, precios y preparación para pedidos/promos'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: canManageModules ? () => context.go(ProductosPage.path) : null,
            ),
          ),
        ],
      ),
    );
  }
}
