import 'package:dio/dio.dart';

import '../../domain/models/stock_models.dart';
import '../datasources/stock_remote_datasource.dart';

class StockRepository {
  StockRepository({required StockRemoteDataSource remoteDataSource}) : _remote = remoteDataSource;
  final StockRemoteDataSource _remote;

  Future<List<StockItem>> list({String? q, bool lowStock = false, bool outOfStock = false}) async {
    try {
      final payload = await _remote.list(q: q, lowStock: lowStock, outOfStock: outOfStock);
      return (payload['data'] as List<dynamic>? ?? []).map((e) => StockItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw StockException(_msg(e));
    }
  }

  Future<StockItem> detail(String productId) async {
    try {
      final payload = await _remote.detail(productId);
      return StockItem.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw StockException(_msg(e));
    }
  }

  Future<List<StockMovement>> movements(String productId) async {
    try {
      final payload = await _remote.movements(productId);
      return (payload['data'] as List<dynamic>? ?? []).map((e) => StockMovement.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw StockException(_msg(e));
    }
  }

  Future<void> adjust({required String productId, String? productVariantId, required double newStock, required String reason, String? notes}) async {
    try {
      await _remote.adjust({'productId': productId, 'productVariantId': productVariantId, 'newStock': newStock, 'reason': reason, 'notes': notes});
    } on DioException catch (e) {
      throw StockException(_msg(e));
    }
  }


  Future<void> createMovement({required String productId, String? productVariantId, required double quantity, required String movementType, required String reason}) async {
    try {
      await _remote.createMovement({
        'productId': productId,
        if (productVariantId != null) 'productVariantId': productVariantId,
        'quantity': quantity,
        'movementType': movementType,
        'reason': reason,
      });
    } on DioException catch (e) {
      throw StockException(_msg(e));
    }
  }

  Future<List<StockLookupItem>> lookupByCode(String query) async {
    try {
      final payload = await _remote.autocomplete(query);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return (data['items'] as List<dynamic>? ?? [])
          .map((e) => StockLookupItem.fromJson(e as Map<String, dynamic>))
          .where((e) => e.effectiveStock > 0)
          .toList();
    } on DioException catch (e) {
      throw StockException(_msg(e));
    }
  }

  String _msg(DioException e) {
    if (e.response?.data is Map<String, dynamic>) return (e.response?.data['message'] as String?) ?? 'Error stock.';
    return 'No se pudo conectar con stock.';
  }
}

class StockException implements Exception {
  StockException(this.message);
  final String message;
}
