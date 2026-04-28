import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/offline/offline_store.dart';

import '../../domain/models/product_model.dart';
import '../datasources/product_remote_datasource.dart';

class ProductRepository {
  ProductRepository({required ProductRemoteDataSource remoteDataSource}) : _remoteDataSource = remoteDataSource;

  final ProductRemoteDataSource _remoteDataSource;
  final OfflineStore _offlineStore = OfflineStore.instance;

  Future<List<ProductModel>> list({required String query, bool? isActive, bool? lowStock}) async {
    try {
      final payload = await _remoteDataSource.fetchProducts(query: query, isActive: isActive, lowStock: lowStock);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final items = (data['items'] as List<dynamic>? ?? []).map((raw) => ProductModel.fromJson(raw as Map<String, dynamic>)).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('products_cache_v1', jsonEncode(payload));
      return items;
    } on DioException catch (error) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('products_cache_v1');
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final data = decoded['data'] as Map<String, dynamic>? ?? {};
        return (data['items'] as List<dynamic>? ?? []).map((raw) => ProductModel.fromJson(raw as Map<String, dynamic>)).toList();
      }
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

  Future<List<ProductCategory>> listCategories({bool includeInactive = false}) async {
    try {
      final payload = await _remoteDataSource.listCategories(includeInactive: includeInactive);
      await _offlineStore.saveCache('product_categories_v1', payload);
      return (payload['data'] as List<dynamic>? ?? [])
          .map((raw) => ProductCategory.fromJson(raw as Map<String, dynamic>))
          .toList();
    } on DioException catch (error) {
      final cached = await _offlineStore.readCache('product_categories_v1');
      if (cached != null) {
        return (cached['data'] as List<dynamic>? ?? [])
            .map((raw) => ProductCategory.fromJson(raw as Map<String, dynamic>))
            .toList();
      }
      throw ProductException(_message(error));
    }
  }

  Future<void> saveCategory({String? id, required String name, String? description}) async {
    try {
      final data = {'name': name, 'description': description};
      if (id == null) {
        await _remoteDataSource.createCategory(data);
      } else {
        await _remoteDataSource.updateCategory(id, data);
      }
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<void> deactivateCategory(String id) async {
    try {
      await _remoteDataSource.deactivateCategory(id);
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<void> activateCategory(String id) async {
    try {
      await _remoteDataSource.activateCategory(id);
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<int> moveCategoryProducts({required String id, required String categoryId}) async {
    try {
      final payload = await _remoteDataSource.moveCategoryProducts(id, categoryId: categoryId);
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      return data['moved'] as int? ?? 0;
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<List<ProductVariantModel>> listVariants(String productId) async {
    try {
      final payload = await _remoteDataSource.listVariants(productId);
      final data = payload['data'] as List<dynamic>? ?? [];
      final items = data.map((raw) => ProductVariantModel.fromJson(raw as Map<String, dynamic>)).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('variants_cache_' + productId, jsonEncode(payload));
      return items;
    } on DioException catch (error) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('variants_cache_' + productId);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final data = decoded['data'] as List<dynamic>? ?? [];
        return data.map((raw) => ProductVariantModel.fromJson(raw as Map<String, dynamic>)).toList();
      }
      throw ProductException(_message(error));
    }
  }

  Future<void> saveVariant(String productId, ProductVariantModel variant, {String? variantId}) async {
    try {
      if (variantId == null) {
        await _remoteDataSource.createVariant(productId, variant.toJson());
      } else {
        await _remoteDataSource.updateVariant(variantId, variant.toJson());
      }
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<void> setVariantActive(String variantId, bool active) async {
    try {
      if (active) {
        await _remoteDataSource.activateVariant(variantId);
      } else {
        await _remoteDataSource.deactivateVariant(variantId);
      }
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<void> deleteVariant(String variantId) async {
    try {
      await _remoteDataSource.deleteVariant(variantId);
    } on DioException catch (error) {
      throw ProductException(_message(error));
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _remoteDataSource.deleteCategory(id);
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
