import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const String path = '/';
  static const String name = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Operativo'),
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
            Text(
              'Estructura base lista para módulos productivos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sesión activa'),
                        const SizedBox(height: 8),
                        Text('Usuario: ${state.session?.email ?? 'sin sesión'}'),
                        Text('Rol: ${state.session?.role ?? 'n/a'}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.route_rounded),
                title: Text('Próximo paso sugerido'),
                subtitle: Text('Implementar módulo de login real + recuperación de contraseña.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
