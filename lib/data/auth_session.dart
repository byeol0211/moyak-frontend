/// In-memory credentials only. Restarting the app requires login again.
abstract final class AuthSession {
  static String? _token;
  static DateTime? _expiresAt;
  static void set(String token, int expiresIn) {
    _token = token;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
  }

  static bool get isAuthenticated =>
      _token != null &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  static void clear() {
    _token = null;
    _expiresAt = null;
  }

  static Map<String, String> headers() {
    if (_token == null) return {};
    if (_expiresAt == null || !DateTime.now().isBefore(_expiresAt!)) {
      throw StateError('로그인이 만료되었어요. 로그아웃 후 다시 로그인해주세요.');
    }
    return {'Authorization': 'Bearer $_token'};
  }
}
