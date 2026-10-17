import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'app_session.dart';
import 'auth_session.dart';

class AuthApi {
  AuthApi({http.Client? client}) : _api = ApiClient(client: client);
  final ApiClient _api;
  Future<bool> available(String username) async {
    final data = await _api.get(
      '/auth/username-available',
      query: {'username': username.trim()},
      timeout: const Duration(seconds: 70),
    );
    if (data is! Map || data['available'] is! bool) {
      throw ApiException('아이디 확인 응답을 읽지 못했어요.');
    }
    return data['available'] as bool;
  }

  Future<void> login(String username, String password) =>
      _authenticate('login', username, password);
  Future<void> signup(String username, String password) =>
      _authenticate('signup', username, password);
  Future<void> _authenticate(
    String action,
    String username,
    String password,
  ) async {
    final data = await _api.post(
      '/auth/$action',
      body: {'username': username.trim(), 'password': password},
      timeout: const Duration(seconds: 70),
    );
    if (data is! Map ||
        data['access_token'] is! String ||
        (data['access_token'] as String).isEmpty ||
        data['expires_in'] is! int ||
        data['expires_in'] <= 0 ||
        data['user'] is! Map ||
        data['user']['id'] is! String ||
        (data['user']['id'] as String).isEmpty ||
        data['token_type'] != 'bearer') {
      throw ApiException('로그인 응답을 읽지 못했어요. 다시 시도해주세요.');
    }
    await AppSession.instance.logout();
    AuthSession.set(data['access_token'], data['expires_in']);
    AppSession.instance.userId = data['user']['id'];
  }

  void close() => _api.close();
}
