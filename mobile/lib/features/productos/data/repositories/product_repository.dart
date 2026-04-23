import 'package:dio/dio.dart';

import '../../domain/models/product_model.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepository {
  ProductRepository({required ProductRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final ProductRemoteDataSource _remoteDataSource;

  Future<List<ProductModel>> list({required String query, bool? isActive, bool? lowStock}) async {
    try {
      final payload = await _remoteDataSource.fetchProducts(query: query, isActive: isActive, lowStock: lowStock);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final items = (data['items'] as List<dynamic>? ?? [])
          .map((raw) => ProductModel.fromJson(raw as Map<String, dynamic>))
          .toList();
      return items;
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<ProductModel> getById(String id) async {
    try {
      final payload = await _remoteDataSource.getProduct(id);
      return ProductModel.fromJson(payload['data'] as Map<String, dynamic>);
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<void> save(ProductModel model, {String? id}) async {
    try {
      if (id == null) {
        await _remoteDataSource.createProduct(model.toJson());
      } else {
        await _remoteDataSource.updateProduct(id, model.toJson());
      }
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<void> deactivate(String id) async {
    try {
      await _remoteDataSource.deactivateProduct(id);
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  String _message(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return (error.response?.data['message'] as String?) ?? 'Error en productos.';
    }
    return 'No se pudo conectar con productos.';
  }
}

class ProductException implements Exception {
  ProductException(this.message);
  final String message;
}
