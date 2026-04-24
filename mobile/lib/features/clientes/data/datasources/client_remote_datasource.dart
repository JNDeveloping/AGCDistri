import '../../../../services/api/api_client.dart';

class ClientRemoteDataSource {
  ClientRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchClients({required String query, bool? isActive, int page = 1, int limit = 20}) {
    return _get(
      '/clientes',
      queryParameters: {
        if (query.isNotEmpty) 'q': query,
        if (isActive != null) 'isActive': isActive,
        'page': page,
        'limit': limit,
      },
    );
  }

  Future<Map<String, dynamic>> getClient(String id) {
    return _get('/clientes/$id');
  }

  Future<Map<String, dynamic>> createClient(Map<String, dynamic> payload) {
    return _post('/clientes', data: payload);
  }

  Future<Map<String, dynamic>> updateClient(String id, Map<String, dynamic> payload) {
    return _put('/clientes/$id', data: payload);
  }

  Future<Map<String, dynamic>> deactivateClient(String id) {
    return _patch('/clientes/$id/deactivate');
  }

  Future<Map<String, dynamic>> activateClient(String id) {
    return _patch('/clientes/$id/activate');
  }

  Future<Map<String, dynamic>> deleteClient(String id) {
    return _delete('/clientes/$id');
  }

  Future<Map<String, dynamic>> listZones({bool includeInactive = false}) {
    return _get('/zones', queryParameters: {'includeInactive': includeInactive});
  }

  Future<Map<String, dynamic>> createZone({required String name, String? description}) {
    return _post('/zones', data: {'name': name, 'description': description});
  }

  Future<Map<String, dynamic>> updateZone(String id, {required String name, String? description}) {
    return _put('/zones/$id', data: {'name': name, 'description': description});
  }

  Future<Map<String, dynamic>> deactivateZone(String id) {
    return _patch('/zones/$id/deactivate');
  }

  Future<Map<String, dynamic>> activateZone(String id) {
    return _patch('/zones/$id/activate');
  }

  Future<Map<String, dynamic>> moveZoneClients(String id, {required String zoneId}) {
    return _patch('/zones/$id/move-clients', data: {'targetZoneId': zoneId});
  }

  Future<Map<String, dynamic>> deleteZone(String id) {
    return _delete('/zones/$id');
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _apiClient.get(path, queryParameters: queryParameters);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? data}) async {
    final response = await _apiClient.post(path, data: data);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> _put(String path, {Map<String, dynamic>? data}) async {
    final response = await _apiClient.put(path, data: data);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> _patch(String path, {Map<String, dynamic>? data}) async {
    final response = await _apiClient.patch(path, data: data);
    return response.data ?? {};
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final response = await _apiClient.delete(path);
    return response.data ?? {};
  }
}
