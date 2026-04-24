import '../../../../services/api/api_client.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> listOrders({String? status, String? clientId, String? sellerId, String? query}) async {
    final response = await _apiClient.get('/orders', queryParameters: {
      if (status != null) 'status': status,
      if (clientId != null) 'clientId': clientId,
      if (sellerId != null) 'sellerId': sellerId,
      if (query != null && query.isNotEmpty) 'orderNumber': query,
    });
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> getOrder(String id) async => (await _apiClient.get('/orders/$id')).data ?? {};
  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> data) async => (await _apiClient.post('/orders', data: data)).data ?? {};
  Future<Map<String, dynamic>> updateOrder(String id, Map<String, dynamic> data) async => (await _apiClient.put('/orders/$id', data: data)).data ?? {};
  Future<Map<String, dynamic>> cancelOrder(String id) async => (await _apiClient.patch('/orders/$id/cancel')).data ?? {};
  Future<Map<String, dynamic>> changeStatus(String id, String status) async => (await _apiClient.patch('/orders/$id/status', data: {'status': status})).data ?? {};

  Future<Map<String, dynamic>> searchClients(String query) async {
    final response = await _apiClient.get('/clientes', queryParameters: {'q': query, 'limit': 20, 'isActive': true});
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> searchProducts(String query) async {
    final response = await _apiClient.get('/productos', queryParameters: {'q': query, 'limit': 30, 'isActive': true});
    return response.data ?? {};
  }
}
