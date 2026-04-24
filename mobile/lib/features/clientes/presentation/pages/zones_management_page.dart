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
  bool? _filterActive;

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
    final visible = _zones.where((z) {
      if (_filterActive == null) return true;
      return z.isActive == _filterActive;
    }).toList();
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
              itemCount: visible.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(label: const Text('Todos'), selected: _filterActive == null, onSelected: (_) => setState(() => _filterActive = null)),
                        ChoiceChip(label: const Text('Activos'), selected: _filterActive == true, onSelected: (_) => setState(() => _filterActive = true)),
                        ChoiceChip(label: const Text('Inactivos'), selected: _filterActive == false, onSelected: (_) => setState(() => _filterActive = false)),
                      ],
                    ),
                  );
                }
                final z = visible[i - 1];
                return ListTile(
                  title: Text(z.name),
                  subtitle: Text(z.description ?? ''),
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: z.isActive ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(z.isActive ? 'Activo' : 'Inactivo'),
                  ),
                  trailing: widget.canManage
                      ? Wrap(
                          spacing: 8,
                          children: [
                            IconButton(onPressed: () => _openEditor(zone: z), icon: const Icon(Icons.edit)),
                            if (z.isActive)
                              IconButton(onPressed: () => _toggleStatus(z, activate: false), icon: const Icon(Icons.block))
                            else
                              IconButton(onPressed: () => _toggleStatus(z, activate: true), icon: const Icon(Icons.check_circle_outline)),
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

  Future<void> _toggleStatus(ClientZone zone, {required bool activate}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(activate ? 'Activar zona' : 'Desactivar zona'),
        content: Text(activate ? '¿Querés activar esta zona?' : '¿Querés desactivar esta zona?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(activate ? 'Activar' : 'Desactivar')),
        ],
      ),
    );
    if (ok != true) return;
    if (activate) {
      await context.read<ClientsCubit>().activateZone(zone.id);
    } else {
      await _deactivate(zone.id);
      return;
    }
    await _load();
  }

  Future<void> _deleteOrMove(ClientZone zone) async {
    try {
      await context.read<ClientsCubit>().deleteZone(zone.id);
      await _load();
    } catch (error) {
      final alternatives = _zones.where((z) => z.id != zone.id && z.isActive).toList();
      if (!mounted || alternatives.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esta zona tiene clientes asociados.')),
        );
        return;
      }
      String? destinationId = alternatives.first.id;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Esta zona tiene clientes asociados'),
          content: StatefulBuilder(
            builder: (context, setStateModal) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Para eliminarla, primero mové los clientes a otra zona.'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: destinationId,
                  items: alternatives.map((z) => DropdownMenuItem(value: z.id, child: Text(z.name))).toList(),
                  onChanged: (value) => setStateModal(() => destinationId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mover clientes')),
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
