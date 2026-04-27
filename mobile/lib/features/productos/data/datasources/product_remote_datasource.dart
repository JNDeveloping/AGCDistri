import '../../../../services/api/api_client.dart';

class ProductRemoteDataSource {
  ProductRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchProducts({required String query, bool? isActive, bool? lowStock}) async {
    final response = await _apiClient.get(
      '/productos',
      queryParameters: {
        if (query.isNotEmpty) 'q': query,
        if (isActive != null) 'isActive': isActive,
        if (lowStock != null && lowStock) 'lowStock': true,
      },
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getProduct(String id) async => (await _apiClient.get('/productos/$id')).data ?? {};
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async => (await _apiClient.post('/productos', data: data)).data ?? {};
  Future<Map<String, dynamic>> updateProduct(String id, Map<String, dynamic> data) async => (await _apiClient.put('/productos/$id', data: data)).data ?? {};
  Future<Map<String, dynamic>> deactivateProduct(String id) async => (await _apiClient.patch('/productos/$id/deactivate')).data ?? {};

  Future<Map<String, dynamic>> listCategories({bool includeInactive = false}) async {
    final response = await _apiClient.get('/product-categories', queryParameters: {'includeInactive': includeInactive});
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async =>
      (await _apiClient.post('/product-categories', data: data)).data ?? {};

  Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> data) async =>
      (await _apiClient.put('/product-categories/$id', data: data)).data ?? {};

  Future<Map<String, dynamic>> deactivateCategory(String id) async =>
      (await _apiClient.patch('/product-categories/$id/deactivate')).data ?? {};

  Future<Map<String, dynamic>> activateCategory(String id) async =>
      (await _apiClient.patch('/product-categories/$id/activate')).data ?? {};

  Future<Map<String, dynamic>> moveCategoryProducts(String id, {required String categoryId}) async =>
      (await _apiClient.patch('/product-categories/$id/move-products', data: {'categoryId': categoryId})).data ?? {};

  Future<Map<String, dynamic>> deleteCategory(String id) async =>
      (await _apiClient.delete('/product-categories/$id')).data ?? {};

  Future<Map<String, dynamic>> listVariants(String productId) async => (await _apiClient.get('/products/$productId/variants')).data ?? {};
  Future<Map<String, dynamic>> createVariant(String productId, Map<String, dynamic> data) async => (await _apiClient.post('/products/$productId/variants', data: data)).data ?? {};
  Future<Map<String, dynamic>> updateVariant(String variantId, Map<String, dynamic> data) async => (await _apiClient.put('/product-variants/$variantId', data: data)).data ?? {};
  Future<Map<String, dynamic>> activateVariant(String variantId) async => (await _apiClient.patch('/product-variants/$variantId/activate')).data ?? {};
  Future<Map<String, dynamic>> deactivateVariant(String variantId) async => (await _apiClient.patch('/product-variants/$variantId/deactivate')).data ?? {};
  Future<Map<String, dynamic>> deleteVariant(String variantId) async => (await _apiClient.delete('/product-variants/$variantId')).data ?? {};
}
