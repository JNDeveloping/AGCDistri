import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/client_repository.dart';
import '../cubit/clients_cubit.dart';

class ZonesManagementPage extends StatefulWidget {
  const ZonesManagementPage({required this.canManage, super.key});

  final bool canManage;

  @override
  State<ZonesManagementPage> createState() => _ZonesManagementPageState();
}

class _ZonesManagementPageState extends State<ZonesManagementPage> {
  bool _loading = true;
  List<ClientZone> _zones = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final zones = await context.read<ClientsCubit>().listZones(includeInactive: true);
    if (mounted) {
      setState(() {
        _zones = zones;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de zonas')),
      floatingActionButton: widget.canManage
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva zona'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _zones.length,
              itemBuilder: (_, i) {
                final z = _zones[i];
                return ListTile(
                  title: Text(z.name),
                  subtitle: Text(z.isActive ? 'Activa' : 'Inactiva'),
                  trailing: widget.canManage
                      ? Wrap(
                          spacing: 8,
                          children: [
                            IconButton(onPressed: () => _openEditor(zone: z), icon: const Icon(Icons.edit)),
                            if (z.isActive)
                              IconButton(onPressed: () => _deactivate(z.id), icon: const Icon(Icons.block)),
                            IconButton(onPressed: () => _deleteOrMove(z), icon: const Icon(Icons.delete_outline)),
                          ],
                        )
                      : null,
                );
              },
            ),
    );
  }

  Future<void> _openEditor({ClientZone? zone}) async {
    final name = TextEditingController(text: zone?.name ?? '');
    final desc = TextEditingController(text: zone?.description ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(zone == null ? 'Nueva zona' : 'Editar zona'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descripción')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      if (zone == null) {
        await context.read<ClientsCubit>().createZone(name: name.text.trim(), description: desc.text.trim().isEmpty ? null : desc.text.trim());
      } else {
        await context.read<ClientsCubit>().updateZone(id: zone.id, name: name.text.trim(), description: desc.text.trim().isEmpty ? null : desc.text.trim());
      }
      await _load();
    }
  }

  Future<void> _deactivate(String id) async {
    await context.read<ClientsCubit>().deactivateZone(id);
    await _load();
  }

  Future<void> _deleteOrMove(ClientZone zone) async {
    try {
      await context.read<ClientsCubit>().deleteZone(zone.id);
      await _load();
    } catch (error) {
      final alternatives = _zones.where((z) => z.id != zone.id && z.isActive).toList();
      if (!mounted || alternatives.isEmpty) return;
      String? destinationId = alternatives.first.id;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Mover clientes a otra zona'),
          content: StatefulBuilder(
            builder: (context, setStateModal) => DropdownButtonFormField<String>(
              value: destinationId,
              items: alternatives.map((z) => DropdownMenuItem(value: z.id, child: Text(z.name))).toList(),
              onChanged: (value) => setStateModal(() => destinationId = value),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mover y eliminar')),
          ],
        ),
      );
      if (proceed == true && destinationId != null) {
        await context.read<ClientsCubit>().moveZoneClients(id: zone.id, zoneId: destinationId!);
        await context.read<ClientsCubit>().deleteZone(zone.id);
        await _load();
      }
    }
  }
}
