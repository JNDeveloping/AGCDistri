import 'package:dio/dio.dart';

import '../../../../core/offline/offline_store.dart';
import '../../domain/models/delivery_model.dart';
import '../datasources/delivery_remote_datasource.dart';

class DeliveryRepository {
  DeliveryRepository({required DeliveryRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final DeliveryRemoteDataSource _remoteDataSource;
  final OfflineStore _offlineStore = OfflineStore.instance;

  Future<List<DeliveryModel>> list({String? date, String? status}) async {
    try {
      final payload = await _remoteDataSource.listDeliveries(date: date, status: status);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (data['items'] as List<dynamic>? ?? [])
          .map((row) => DeliveryModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw DeliveryException(_message(error));
    }
  }

  Future<List<DeliveryZoneModel>> listZones() async {
    try {
      final payload = await _remoteDataSource.listZones();
      await _offlineStore.saveCache('delivery_zones_v1', payload);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (data['items'] as List<dynamic>? ?? [])
          .map((row) => DeliveryZoneModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      final cached = await _offlineStore.readCache('delivery_zones_v1');
      if (cached != null) {
        final data = cached['data'] as Map<String, dynamic>? ?? {};
        return (data['items'] as List<dynamic>? ?? [])
            .map((row) => DeliveryZoneModel.fromJson(row as Map<String, dynamic>))
            .toList();
      }
      throw DeliveryException(_message(error));
    }
  }

  Future<List<DeliveryOrderModel>> listPendingOrders(String zoneId) async {
    try {
      final payload = await _remoteDataSource.pendingOrders(zoneId);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (data['items'] as List<dynamic>? ?? [])
          .map((row) => DeliveryOrderModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      throw DeliveryException(_message(error));
    }
  }

  Future<DeliveryModel> create({
    required String zoneId,
    required List<String> orderIds,
    String? date,
    String? driverId,
    String? notes,
  }) async {
    try {
      final payload = await _remoteDataSource.createDelivery({
        'zoneId': zoneId,
        'orderIds': orderIds,
        if (date != null) 'date': date,
        if (driverId != null) 'driverId': driverId,
        if (notes != null) 'notes': notes,
      });
      return DeliveryModel.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (error) {
      throw DeliveryException(_message(error));
    }
  }

  Future<DeliveryModel> getById(String id) async {
    try {
      final payload = await _remoteDataSource.getDelivery(id);
      return DeliveryModel.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (error) {
      throw DeliveryException(_message(error));
    }
  }

  Future<void> optimizeRoute(String id, {double? lat, double? lng}) async {
    try {
      await _remoteDataSource.optimizeRoute(id, latitude: lat, longitude: lng);
    } on DioException catch (error) {
      throw DeliveryException(_message(error));
    }
  }

  Future<void> updateOrderStatus(String deliveryOrderId, {required String status, String? reason, bool? collectedCash, double? collectedAmount}) async {
    try {
      await _remoteDataSource.updateDeliveryOrderStatus(
        deliveryOrderId,
        status: status,
        reason: reason,
        collectedCash: collectedCash,
        collectedAmount: collectedAmount,
      );
    } on DioException catch (error) {
      throw DeliveryException(_message(error));
    }
  }

  Future<void> markDelivered(String deliveryOrderId, {bool? collectedCash, double? collectedAmount}) async {
    final localRequestId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    try {
      await _remoteDataSource.markDelivered(deliveryOrderId, clientRequestId: localRequestId, collectedCash: collectedCash, collectedAmount: collectedAmount);
    } on DioException catch (error) {
      final isOffline = error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.unknown;
      if (isOffline) {
        await _offlineStore.enqueue(actionType: 'mark_delivery_status', payload: {
          'path': '/delivery-orders/$deliveryOrderId/delivered',
          'data': {
            'clientRequestId': localRequestId,
            if (collectedCash != null) 'collectedCash': collectedCash,
            if (collectedAmount != null) 'collectedAmount': collectedAmount,
          },
        });
        throw DeliveryException('Sin conexión: entrega registrada localmente para sincronizar.');
      }
      throw DeliveryException(_message(error));
    }
  }

  Future<void> markNotDelivered(String deliveryOrderId, {required String reason}) async {
    final localRequestId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    try {
      await _remoteDataSource.markNotDelivered(deliveryOrderId, reason: reason, clientRequestId: localRequestId);
    } on DioException catch (error) {
      final isOffline = error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout || error.type == DioExceptionType.unknown;
      if (isOffline) {
        await _offlineStore.enqueue(actionType: 'mark_delivery_status', payload: {
          'path': '/delivery-orders/$deliveryOrderId/not-delivered',
          'data': {'clientRequestId': localRequestId, 'reason': reason},
        });
        throw DeliveryException('Sin conexión: estado guardado localmente para sincronizar.');
      }
      throw DeliveryException(_message(error));
    }
  }

  Future<void> markRescheduled(String deliveryOrderId, {String? notes}) async {
    try {
      await _remoteDataSource.markRescheduled(deliveryOrderId, notes: notes);
    } on DioException catch (error) {
      throw DeliveryException(_message(error));
    }
  }

  String _message(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return (error.response?.data['message'] as String?) ?? 'Error en repartos.';
    }
    return 'No se pudo conectar con repartos.';
  }
}

class DeliveryException implements Exception {
  DeliveryException(this.message);

  final String message;
}
