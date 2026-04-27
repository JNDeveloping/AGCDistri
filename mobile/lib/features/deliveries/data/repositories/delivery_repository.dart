import 'package:dio/dio.dart';

import '../../domain/models/delivery_model.dart';
import '../datasources/delivery_remote_datasource.dart';

class DeliveryRepository {
  DeliveryRepository({required DeliveryRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final DeliveryRemoteDataSource _remoteDataSource;

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

  Future<DeliveryModel> create({String? date, String? driverId, String? notes, String? zone}) async {
    try {
      final payload = await _remoteDataSource.createDelivery({
        if (date != null) 'date': date,
        if (driverId != null) 'driverId': driverId,
        if (notes != null) 'notes': notes,
        if (zone != null) 'zone': zone,
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
