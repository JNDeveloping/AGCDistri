import '../../../../services/api/api_client.dart';

class UsersRemoteDataSource {
  UsersRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> listUsers() async => (await _apiClient.get('/users')).data ?? {};

  Future<Map<String, dynamic>> createUser(Map<String, dynamic> payload) async =>
      (await _apiClient.post('/users', data: payload)).data ?? {};

  Future<Map<String, dynamic>> updateUser(String id, Map<String, dynamic> payload) async =>
      (await _apiClient.put('/users/$id', data: payload)).data ?? {};

  Future<Map<String, dynamic>> deactivateUser(String id) async =>
      (await _apiClient.patch('/users/$id/deactivate')).data ?? {};

  Future<Map<String, dynamic>> activateUser(String id) async =>
      (await _apiClient.patch('/users/$id/activate')).data ?? {};

  Future<Map<String, dynamic>> deleteUser(String id) async =>
      (await _apiClient.delete('/users/$id')).data ?? {};
}
