import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage;

  Future<void> save(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> read() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clear() {
    return _storage.delete(key: _tokenKey);
  }
}
