import '../../../../services/api/api_client.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    return response.data ?? {};
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _apiClient.get('/auth/me');
    return response.data ?? {};
  }
}
