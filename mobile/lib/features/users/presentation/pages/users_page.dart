import 'package:flutter/material.dart';

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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (_, index) {
                      final user = _users[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?')),
                          title: Text(user.fullName),
                          subtitle: Text('${user.email}\nRol: ${user.role}${user.isActive ? '' : ' · Inactivo'}'),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _openForm(user: user);
                              if (value == 'deactivate' && user.isActive) _confirmDeactivate(user);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Editar')),
                              if (user.isActive) const PopupMenuItem(value: 'deactivate', child: Text('Desactivar')),
                            ],
                          ),
                        ),
                      );
                    },
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
      await widget.repository.deactivate(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario desactivado.')));
      }
      await _load();
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
