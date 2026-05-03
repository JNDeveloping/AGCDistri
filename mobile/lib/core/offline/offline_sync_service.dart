import 'package:dio/dio.dart';

import '../../services/api/api_client.dart';
import 'offline_store.dart';

class OfflineSyncService {
  OfflineSyncService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;
  final OfflineStore _store = OfflineStore.instance;

  Future<void> syncPending() async {
    final pending = await _store.listQueue(status: OfflineQueueStatus.pending);
    for (final item in pending) {
      await _store.setQueueStatus(item.id, OfflineQueueStatus.syncing);
      try {
        await _send(item);
        await _store.setQueueStatus(item.id, OfflineQueueStatus.synced);
      } on DioException catch (e) {
        final status = e.response?.statusCode == 409 ? OfflineQueueStatus.needsReview : OfflineQueueStatus.error;
        final message = e.response?.data is Map<String, dynamic>
            ? ((e.response!.data as Map<String, dynamic>)['message'] as String?) ?? 'Error de sincronización'
            : 'Error de sincronización';
        await _store.setQueueStatus(item.id, status, errorMessage: message, incrementAttempts: true);
      } catch (_) {
        await _store.setQueueStatus(item.id, OfflineQueueStatus.error, errorMessage: 'Error desconocido', incrementAttempts: true);
      }
    }
  }

  Future<void> retryErrors() async {
    final errors = await _store.listQueue(status: OfflineQueueStatus.error);
    for (final item in errors) {
      await _store.setQueueStatus(item.id, OfflineQueueStatus.pending, errorMessage: null);
    }
    await syncPending();
  }

  Future<void> _send(OfflineQueueItem item) async {
    final payload = item.payload;
    switch (item.actionType) {
      case 'create_order':
        await _apiClient.post('/orders', data: payload);
        return;
      case 'register_payment':
        await _apiClient.post('/client-payments', data: payload);
        return;
      case 'update_client_location':
        await _apiClient.patch('/clientes/${payload['clientId']}', data: payload['data'] as Map<String, dynamic>);
        return;
      case 'mark_delivery_status':
        await _apiClient.patch(payload['path'] as String, data: payload['data'] as Map<String, dynamic>);
        return;
      case 'create_note':
        await _apiClient.post('/clients/${payload['clientId']}/notes', data: payload['data'] as Map<String, dynamic>);
        return;
      default:
        throw Exception('Tipo de acción no soportado: ${item.actionType}');
    }
  }
}
