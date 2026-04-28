import '../../../../services/api/api_client.dart';

class DeliveryRemoteDataSource {
  DeliveryRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> listDeliveries({String? date, String? status, int page = 1, int limit = 20}) async {
    final response = await _apiClient.get('/deliveries', queryParameters: {
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      'page': page,
      'limit': limit,
    });
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> listZones() async => (await _apiClient.get('/deliveries/zones')).data ?? {};

  Future<Map<String, dynamic>> createDelivery(Map<String, dynamic> payload) async =>
      (await _apiClient.post('/deliveries', data: payload)).data ?? {};

  Future<Map<String, dynamic>> getDelivery(String id) async => (await _apiClient.get('/deliveries/$id')).data ?? {};

  Future<Map<String, dynamic>> assignDriver(String id, String driverId) async =>
      (await _apiClient.patch('/deliveries/$id/assign-driver', data: {'driverId': driverId})).data ?? {};

  Future<Map<String, dynamic>> addOrders(String id, List<String> orderIds) async =>
      (await _apiClient.post('/deliveries/$id/orders', data: {'orderIds': orderIds})).data ?? {};

  Future<Map<String, dynamic>> pendingOrders(String zoneId) async =>
      (await _apiClient.get('/deliveries/pending-orders', queryParameters: {'zone_id': zoneId})).data ?? {};

  Future<Map<String, dynamic>> todayRoutes() async => (await _apiClient.get('/routes/today')).data ?? {};

  Future<Map<String, dynamic>> optimizeRoute(String id, {double? latitude, double? longitude}) async =>
      (await _apiClient.post('/deliveries/$id/optimize-route', data: {
        if (latitude != null) 'currentLatitude': latitude,
        if (longitude != null) 'currentLongitude': longitude,
      })).data ?? {};

  Future<Map<String, dynamic>> updateDeliveryOrderStatus(
    String deliveryOrderId, {
    required String status,
    String? reason,
    bool? collectedCash,
    double? collectedAmount,
  }) async =>
      (await _apiClient.patch('/deliveries/orders/$deliveryOrderId/status', data: {
        'status': status,
        if (reason != null) 'reason': reason,
        if (collectedCash != null) 'collectedCash': collectedCash,
        if (collectedAmount != null) 'collectedAmount': collectedAmount,
      })).data ?? {};

  Future<Map<String, dynamic>> markDelivered(
    String deliveryOrderId, {
    bool? collectedCash,
    double? collectedAmount,
  }) async =>
      (await _apiClient.patch('/delivery-orders/$deliveryOrderId/delivered', data: {
        if (collectedCash != null) 'collectedCash': collectedCash,
        if (collectedAmount != null) 'collectedAmount': collectedAmount,
      })).data ?? {};

  Future<Map<String, dynamic>> markNotDelivered(String deliveryOrderId, {required String reason}) async =>
      (await _apiClient.patch('/delivery-orders/$deliveryOrderId/not-delivered', data: {'reason': reason})).data ?? {};

  Future<Map<String, dynamic>> markRescheduled(String deliveryOrderId, {String? notes}) async =>
      (await _apiClient.patch('/delivery-orders/$deliveryOrderId/reschedule', data: {if (notes != null) 'notes': notes})).data ?? {};
}
