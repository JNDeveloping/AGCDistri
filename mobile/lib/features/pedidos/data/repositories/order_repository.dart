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
      throw _mapError(e);
    }
  }

  Future<OrderModel> getById(String id) async {
    try {
      final payload = await _remoteDataSource.getOrder(id);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<OrderModel> save({
    String? id,
    required String clientId,
    required List<OrderItemInput> items,
    double discountTotal = 0,
    String? paymentTerms,
    String? notes,
  }) async {
    try {
      final data = {
        'clientId': clientId,
        'items': items.map((e) => e.toJson()).toList(),
        'discountTotal': discountTotal,
        'paymentTerms': paymentTerms,
        'notes': notes,
      };
      final payload = id == null ? await _remoteDataSource.createOrder(data) : await _remoteDataSource.updateOrder(id, data);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<OrderModel> cancel(String id) async {
    try {
      final payload = await _remoteDataSource.cancelOrder(id);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<OrderModel> changeStatus(String id, String status) async {
    try {
      final payload = await _remoteDataSource.changeStatus(id, status);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<OrderStockValidation> validateStock(String id) async {
    try {
      final payload = await _remoteDataSource.validateStock(id);
      return OrderStockValidation.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _remoteDataSource.deleteOrder(id);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<OrderClientLookup>> searchClients(String query) async {
    final payload = await _remoteDataSource.searchClients(query);
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return (data['items'] as List<dynamic>? ?? []).map((e) => OrderClientLookup.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderProductVariantLookup>> searchProductVariants(String productId) async {
    final payload = await _remoteDataSource.getProductVariants(productId);
    final data = payload['data'] as List<dynamic>? ?? [];
    return data.map((e) => OrderProductVariantLookup.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderProductLookup>> searchProducts(String query) async {
    final payload = await _remoteDataSource.searchProducts(query);
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return (data['items'] as List<dynamic>? ?? []).map((e) => OrderProductLookup.fromJson(e as Map<String, dynamic>)).toList();
  }

  OrderException _mapError(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      final data = error.response?.data as Map<String, dynamic>;
      final details = data['details'];
      final detailMap = details is Map<String, dynamic> ? details : const <String, dynamic>{};
      return OrderException(
        message: (data['message'] as String?) ?? 'Error en pedidos.',
        code: (data['code'] as String?) ?? (detailMap['code'] as String?),
        productName: (data['productName'] as String?) ?? (detailMap['productName'] as String?),
        availableStock: ((data['availableStock'] ?? detailMap['availableStock']) as num?)?.toDouble(),
      );
    }

    return const OrderException(message: 'No se pudo conectar con pedidos.');
  }
}

class OrderException implements Exception {
  const OrderException({
    required this.message,
    this.code,
    this.productName,
    this.availableStock,
  });

  final String message;
  final String? code;
  final String? productName;
  final double? availableStock;

  bool get isInsufficientStock => code == 'INSUFFICIENT_STOCK';

  @override
  String toString() => message;
}
