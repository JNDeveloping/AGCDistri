import '../../../../services/api/api_client.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> listOrders({
    String? status,
    String? clientId,
    String? sellerId,
    String? zoneId,
    String? paymentCondition,
    String? search,
    String? dateFrom,
    String? dateTo,
    String? sortBy,
    String? sortDirection,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _apiClient.get('/orders', queryParameters: {
      if (status != null) 'status': status,
      if (clientId != null) 'clientId': clientId,
      if (sellerId != null) 'sellerId': sellerId,
      if (zoneId != null) 'zoneId': zoneId,
      if (paymentCondition != null) 'paymentCondition': paymentCondition,
      if (search != null && search.isNotEmpty) 'search': search,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDirection != null) 'sortDirection': sortDirection,
      'page': page,
      'limit': limit,
    });
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getOrder(String id) async => (await _apiClient.get('/orders/$id')).data ?? {};
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async => (await _apiClient.post('/orders', data: data)).data ?? {};
  Future<Map<String, dynamic>> updateOrder(String id, Map<String, dynamic> data) async => (await _apiClient.put('/orders/$id', data: data)).data ?? {};
  Future<Map<String, dynamic>> cancelOrder(String id) async => (await _apiClient.patch('/orders/$id/cancel')).data ?? {};
  Future<Map<String, dynamic>> changeStatus(String id, String status) async => (await _apiClient.patch('/orders/$id/status', data: {'status': status})).data ?? {};
  Future<Map<String, dynamic>> validateStock(String id) async => (await _apiClient.get('/orders/$id/stock-validation')).data ?? {};
  Future<Map<String, dynamic>> deleteOrder(String id) async => (await _apiClient.delete('/orders/$id')).data ?? {};

  Future<Map<String, dynamic>> searchClients(String query) async {
    final response = await _apiClient.get('/clientes', queryParameters: {'q': query, 'limit': 20, 'isActive': true});
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getProductVariants(String productId) async => (await _apiClient.get('/products/$productId/variants')).data ?? {};

  Future<Map<String, dynamic>> searchProducts(String query) async {
    final response = await _apiClient.get('/productos/autocomplete', queryParameters: {'q': query, 'limit': 30});
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getPurchaseHistory(String clientId) async =>
      (await _apiClient.get('/clients/$clientId/purchase-history')).data ?? {};

  Future<Map<String, dynamic>> getSuggestedProducts(String clientId) async =>
      (await _apiClient.get('/clients/$clientId/suggested-products')).data ?? {};

  Future<Map<String, dynamic>> getLastOrder(String clientId) async =>
      (await _apiClient.get('/clients/$clientId/last-order')).data ?? {};
}
