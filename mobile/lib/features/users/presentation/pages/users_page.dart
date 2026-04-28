import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/repositories/users_repository.dart';
import '../../domain/models/app_user.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({required this.repository, super.key});

  static const path = '/profile/users';

  final UsersRepository repository;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  bool _loading = true;
  String? _error;
  List<AppUser> _users = const [];
  bool? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await widget.repository.list();
      if (mounted) {
        setState(() => _users = users);
      }
    } on UsersException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.select((AuthCubit cubit) => cubit.state.session?.user.id);
    final visibleUsers = _users.where((u) {
      if (_statusFilter == null) return true;
      return u.isActive == _statusFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Nuevo usuario'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Todos'),
                            selected: _statusFilter == null,
                            onSelected: (_) => setState(() => _statusFilter = null),
                          ),
                          ChoiceChip(
                            label: const Text('Activos'),
                            selected: _statusFilter == true,
                            onSelected: (_) => setState(() => _statusFilter = true),
                          ),
                          ChoiceChip(
                            label: const Text('Inactivos'),
                            selected: _statusFilter == false,
                            onSelected: (_) => setState(() => _statusFilter = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...visibleUsers.map(
                        (user) => Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?')),
                            title: Row(
                              children: [
                                Expanded(child: Text(user.fullName)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    user.isActive ? 'Activo' : 'Inactivo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: user.isActive ? Colors.green.shade900 : Colors.red.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text('${user.email}\nRol: ${user.role}'),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') _openForm(user: user);
                                if (value == 'deactivate' && user.isActive) _confirmDeactivate(user);
                                if (value == 'activate' && !user.isActive) _activate(user);
                                if (value == 'delete') _confirmDelete(user, currentUserId);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Editar')),
                                if (user.isActive) const PopupMenuItem(value: 'deactivate', child: Text('Desactivar')),
                                if (!user.isActive) const PopupMenuItem(value: 'activate', child: Text('Activar')),
                                const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                              ],
                            ),
                            titleAlignment: ListTileTitleAlignment.center,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _confirmDeactivate(AppUser user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Desactivar usuario'),
        content: Text('¿Confirmás desactivar a ${user.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desactivar')),
        ],
      ),
    );

    if (ok == true) {
      try {
        await widget.repository.deactivate(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario desactivado.')));
        }
        await _load();
      } on UsersException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    }
  }

  Future<void> _activate(AppUser user) async {
    try {
      await widget.repository.activate(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario activado.')));
      }
      await _load();
    } on UsersException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _confirmDelete(AppUser user, String? currentUserId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('Esta acción eliminará a ${user.fullName} si no tiene movimientos asociados. ¿Continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton.tonal(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    if (currentUserId != null && currentUserId == user.id) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No podés eliminar el usuario con el que estás logueado.')),
        );
      }
      return;
    }

    try {
      await widget.repository.delete(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado correctamente.')));
      }
      await _load();
    } on UsersException catch (e) {
      if (!mounted) return;
      if (e.canDeactivate) {
        final shouldDeactivate = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No se puede eliminar'),
            content: const Text('No se puede eliminar este usuario porque tiene movimientos asociados. Podés desactivarlo.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cerrar')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desactivar usuario')),
            ],
          ),
        );
        if (shouldDeactivate == true) {
          await widget.repository.deactivate(user.id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario desactivado.')));
          }
          await _load();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _openForm({AppUser? user}) async {
    final fullName = TextEditingController(text: user?.fullName ?? '');
    final email = TextEditingController(text: user?.email ?? '');
    final password = TextEditingController();
    String role = user?.role ?? 'vendedor';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user == null ? 'Crear usuario' : 'Editar usuario', style: Theme.of(context).textTheme.titleLarge),
            TextField(controller: fullName, decoration: const InputDecoration(labelText: 'Nombre completo')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('admin')),
                DropdownMenuItem(value: 'vendedor', child: Text('vendedor')),
                DropdownMenuItem(value: 'repartidor', child: Text('repartidor')),
              ],
              onChanged: (value) => role = value ?? role,
            ),
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(labelText: user == null ? 'Contraseña' : 'Nueva contraseña (opcional)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await widget.repository.save(
                  id: user?.id,
                  fullName: fullName.text.trim(),
                  email: email.text.trim(),
                  role: role,
                  password: password.text.trim().isEmpty ? null : password.text.trim(),
                );
                if (mounted) Navigator.pop(context, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario guardado.')));
    }
  }
}
