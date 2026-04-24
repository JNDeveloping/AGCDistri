import 'package:dio/dio.dart';

import '../../domain/models/order_model.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepository {
  OrderRepository({required OrderRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final OrderRemoteDataSource _remoteDataSource;

  Future<List<OrderModel>> list({String? status, String? query}) async {
    try {
      final payload = await _remoteDataSource.listOrders(status: status, query: query);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (data['items'] as List<dynamic>? ?? []).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw OrderException(_message(e));
    }
  }

  Future<OrderModel> getById(String id) async {
    try {
      final payload = await _remoteDataSource.getOrder(id);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrderException(_message(e));
    }
  }

  Future<OrderModel> save({String? id, required String clientId, required List<OrderItemInput> items, double discountTotal = 0, double taxTotal = 0, String? paymentTerms, String? notes, String? deliveryAddress}) async {
    try {
      final data = {
        'clientId': clientId,
        'items': items.map((e) => e.toJson()).toList(),
        'discountTotal': discountTotal,
        'taxTotal': taxTotal,
        'paymentTerms': paymentTerms,
        'notes': notes,
        'deliveryAddress': deliveryAddress,
      };
      final payload = id == null ? await _remoteDataSource.createOrder(data) : await _remoteDataSource.updateOrder(id, data);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrderException(_message(e));
    }
  }

  Future<OrderModel> cancel(String id) async {
    try {
      final payload = await _remoteDataSource.cancelOrder(id);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrderException(_message(e));
    }
  }

  Future<OrderModel> changeStatus(String id, String status) async {
    try {
      final payload = await _remoteDataSource.changeStatus(id, status);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw OrderException(_message(e));
    }
  }

  Future<List<OrderClientLookup>> searchClients(String query) async {
    final payload = await _remoteDataSource.searchClients(query);
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return (data['items'] as List<dynamic>? ?? []).map((e) => OrderClientLookup.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderProductLookup>> searchProducts(String query) async {
    final payload = await _remoteDataSource.searchProducts(query);
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return (data['items'] as List<dynamic>? ?? []).map((e) => OrderProductLookup.fromJson(e as Map<String, dynamic>)).toList();
  }

  String _message(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return (error.response?.data['message'] as String?) ?? 'Error en pedidos.';
    }
    return 'No se pudo conectar con pedidos.';
  }
}

class OrderException implements Exception {
  OrderException(this.message);
  final String message;
}
