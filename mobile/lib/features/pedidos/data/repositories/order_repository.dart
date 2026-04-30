import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/offline/offline_store.dart';

import '../../domain/models/order_model.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepository {
  OrderRepository({required OrderRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final OrderRemoteDataSource _remoteDataSource;
  final OfflineStore _offlineStore = OfflineStore.instance;

  Future<OrdersListResult> list({
    String? status,
    String? search,
    String? zoneId,
    String? paymentCondition,
    String? archived,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortDirection,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final payload = await _remoteDataSource.listOrders(
        status: status,
        search: search,
        zoneId: zoneId,
        paymentCondition: paymentCondition,
        archived: archived,
        dateFrom: dateFrom,
        dateTo: dateTo,
        sortBy: sortBy,
        sortDirection: sortDirection,
        page: page,
        limit: limit,
      );
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final result = OrdersListResult(
        items: (data['items'] as List<dynamic>? ?? []).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList(),
        total: (data['total'] as num?)?.toInt() ?? 0,
        page: (data['page'] as num?)?.toInt() ?? page,
        totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
        countsByStatus: (data['countsByStatus'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
      );
      await _offlineStore.saveCache('orders_cache_v1', payload);
      return result;
    } on DioException catch (e) {
      final decoded = await _offlineStore.readCache('orders_cache_v1');
      if (decoded != null) {
        final data = decoded['data'] as Map<String, dynamic>? ?? {};
        return OrdersListResult(
          items: (data['items'] as List<dynamic>? ?? []).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList(),
          total: (data['total'] as num?)?.toInt() ?? 0,
          page: (data['page'] as num?)?.toInt() ?? 1,
          totalPages: (data['totalPages'] as num?)?.toInt() ?? 1,
          countsByStatus: (data['countsByStatus'] as Map<String, dynamic>? ?? const {})
              .map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0)),
        );
      }
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
    final localRequestId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    try {
      final data = {
        'clientRequestId': localRequestId,
        'clientId': clientId,
        'items': items.map((e) => e.toJson()).toList(),
        'discountTotal': discountTotal,
        'paymentTerms': paymentTerms,
        'notes': notes,
      };
      final payload = id == null ? await _remoteDataSource.createOrder(data) : await _remoteDataSource.updateOrder(id, data);
      return OrderModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      final isOffline = e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.unknown;
      if (id == null && isOffline) {
        final payload = {
          'clientRequestId': localRequestId,
          'clientId': clientId,
          'items': items.map((entry) => entry.toJson()).toList(),
          'discountTotal': discountTotal,
          'paymentTerms': paymentTerms,
          'notes': notes,
        };
        await _offlineStore.enqueue(actionType: 'create_order', payload: payload);
        throw const OrderException(message: 'Sin conexión: pedido guardado localmente. Estado: Pendiente de sincronizar.');
      }
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
    final raw = (data['items'] as List<dynamic>? ?? []).map((e) => OrderProductLookup.fromJson(e as Map<String, dynamic>)).toList();
    final grouped = <String, OrderProductLookup>{};
    for (final item in raw) {
      final existing = grouped[item.id];
      if (existing == null) {
        grouped[item.id] = OrderProductLookup(
          id: item.id,
          name: item.name,
          internalCode: item.internalCode,
          barcode: item.barcode,
          brand: item.brand,
          categoryName: item.categoryName,
          salePrice: item.salePrice,
          stockCurrent: item.stockCurrent,
          hasVariants: item.hasVariants,
          variantId: null,
          variantName: null,
        );
        continue;
      }
      grouped[item.id] = OrderProductLookup(
        id: existing.id,
        name: existing.name,
        internalCode: existing.internalCode,
        barcode: existing.barcode,
        brand: existing.brand,
        categoryName: existing.categoryName,
        salePrice: existing.salePrice,
        stockCurrent: item.hasVariants ? (existing.stockCurrent + item.stockCurrent) : existing.stockCurrent,
        hasVariants: existing.hasVariants || item.hasVariants,
        variantId: null,
        variantName: null,
      );
    }
    return grouped.values.toList();
  }


  Future<List<ClientPurchaseHistoryItem>> getPurchaseHistory(String clientId) async {
    try {
      final payload = await _remoteDataSource.getPurchaseHistory(clientId);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (data['items'] as List<dynamic>? ?? [])
          .map((e) => ClientPurchaseHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<SuggestedProductItem>> getSuggestedProducts(String clientId) async {
    try {
      final payload = await _remoteDataSource.getSuggestedProducts(clientId);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (data['items'] as List<dynamic>? ?? [])
          .map((e) => SuggestedProductItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ClientLastOrderSuggestion> getLastOrder(String clientId) async {
    try {
      final payload = await _remoteDataSource.getLastOrder(clientId);
      return ClientLastOrderSuggestion.fromJson(payload['data'] as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Map<String, dynamic>> previewPromotions({
    required String clientId,
    required List<OrderItemInput> items,
  }) async {
    try {
      return await _remoteDataSource.previewPromotions({
        'client_id': clientId,
        'items': items.map((e) => {
          'product_id': e.productId,
          'variant_id': e.productVariantId,
          'quantity': e.quantity,
          'unit_price': 0,
        }).toList(),
      });
    } on DioException catch (e) {
      throw _mapError(e);
    }
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
        variantName: (data['variantName'] as String?) ?? (detailMap['variantName'] as String?),
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
    this.variantName,
    this.availableStock,
  });

  final String message;
  final String? code;
  final String? productName;
  final String? variantName;
  final double? availableStock;

  bool get isInsufficientStock => code == 'INSUFFICIENT_STOCK';

  @override
  String toString() => message;
}

class OrdersListResult {
  const OrdersListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.countsByStatus,
  });

  final List<OrderModel> items;
  final int total;
  final int page;
  final int totalPages;
  final Map<String, int> countsByStatus;
}
