import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_bottom_nav_bar.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../company_settings/presentation/pages/company_settings_page.dart';
import '../../../clientes/presentation/pages/zones_management_page.dart';
import '../../../productos/presentation/pages/product_categories_page.dart';
import '../../../users/data/repositories/users_repository.dart';
import '../../../users/presentation/pages/users_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.usersRepository, super.key});

  static const path = '/profile';
  static const name = 'profile';

  final UsersRepository usersRepository;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  IconData _avatarIcon = Icons.person_rounded;

  @override
  Widget build(BuildContext context) {
    final session = context.select((AuthCubit cubit) => cubit.state.session);
    final role = session?.user.role ?? 'vendedor';
    final isAdmin = role == 'admin';

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      bottomNavigationBar: AppBottomNavBar(currentRoute: ProfilePage.path, role: role),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 34, child: Icon(_avatarIcon, size: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(session?.user.fullName ?? '-', style: Theme.of(context).textTheme.titleLarge),
                      Text(session?.user.email ?? '-'),
                      Text('Rol: $role'),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cambiar avatar',
                  icon: const Icon(Icons.edit),
                  onPressed: _changeAvatar,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: const Text('Mi cuenta'),
              subtitle: const Text('Datos del usuario actual y sesión'),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Mi cuenta'),
                  content: Text(
                    'Nombre: ${session?.user.fullName ?? '-'}\n'
                    'Email: ${session?.user.email ?? '-'}\n'
                    'Rol: ${session?.user.role ?? '-'}\n\n'
                    'Cambio de contraseña: disponible para admin desde Usuarios.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
                  ],
                ),
              ),
            ),
          ),
          if (isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Usuarios'),
                subtitle: const Text('Crear, editar, desactivar y asignar roles'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UsersPage(repository: widget.usersRepository)),
                ),
              ),
            ),

          if (isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.route_rounded),
                title: const Text('Zonas'),
                subtitle: const Text('Gestionar zonas y mover clientes'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ZonesManagementPage(canManage: true)),
                ),
              ),
            ),
          if (isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.category_rounded),
                title: const Text('Categorías'),
                subtitle: const Text('Gestionar categorías y mover productos'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductCategoriesPage(canManage: true)),
                ),
              ),
            ),
          if (isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.business_rounded),
                title: const Text('Configuración de Empresa'),
                subtitle: const Text('Nombre, paleta, ganancia, redondeo y datos generales'),
                onTap: () => context.push(CompanySettingsPage.path),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Cerrar sesión'),
              onTap: () => context.read<AuthCubit>().logout(),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Aplicacion desarrollada por Tomas Victola',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _changeAvatar() async {
    final options = [
      Icons.person_rounded,
      Icons.account_circle_rounded,
      Icons.face_rounded,
      Icons.person_pin_rounded,
    ];

    final selected = await showModalBottomSheet<IconData>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: options
              .map(
                (icon) => ListTile(
                  leading: Icon(icon),
                  title: Text(icon.codePoint.toString()),
                  onTap: () => Navigator.pop(context, icon),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() => _avatarIcon = selected);
    }
  }
}
