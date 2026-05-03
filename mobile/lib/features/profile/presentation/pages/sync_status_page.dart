import 'package:flutter/material.dart';

import '../../../../core/offline/offline_store.dart';
import '../../../../core/offline/offline_sync_service.dart';

class SyncStatusPage extends StatefulWidget {
  const SyncStatusPage({required this.syncService, super.key});

  final OfflineSyncService syncService;

  @override
  State<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends State<SyncStatusPage> {
  final _store = OfflineStore.instance;
  bool _busy = false;
  List<OfflineQueueItem> _items = const [];
  Map<OfflineQueueStatus, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _store.listQueue();
    final counts = await _store.queueCounts();
    if (!mounted) return;
    setState(() {
      _items = items.reversed.toList();
      _counts = counts;
    });
  }

  Future<void> _syncNow() async {
    setState(() => _busy = true);
    await widget.syncService.syncPending();
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    await widget.syncService.retryErrors();
    await _load();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OfflineQueueStatus.values
                  .map((status) => Chip(label: Text('${status.name}: ${_counts[status] ?? 0}')))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _syncNow,
                    icon: const Icon(Icons.sync),
                    label: const Text('Sincronizar ahora'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_items.isEmpty) const Text('Sin acciones offline registradas.'),
            ..._items.map(
              (e) => Card(
                child: ListTile(
                  title: Text(e.actionType),
                  subtitle: Text('Estado: ${e.status.name}\nIntentos: ${e.attempts}${e.errorMessage != null ? '\nError: ${e.errorMessage}' : ''}'),
                  trailing: Text('#${e.id}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
