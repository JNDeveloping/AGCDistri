class TokenStorage {
  String? _token;

  String? get token => _token;

  Future<void> save(String token) async {
    _token = token;
  }

  Future<void> clear() async {
    _token = null;
  }
}
