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
  Future<void> signup(
    String username,
    String password, {
    required String name,
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ApiException('이름을 입력해주세요.');
    }
    await _authenticate('signup', username, password, name: normalizedName);
  }

  Future<void> _authenticate(
    String action,
    String username,
    String password, {
    String? name,
  }) async {
    final data = await _api.post(
      '/auth/$action',
      body: {
        'username': username.trim(),
        'password': password,
        if (name != null) 'name': name.trim(),
      },
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
    AppSession.instance.userName = data['user']['name'] is String
        ? data['user']['name'] as String
        : null;
    AppSession.instance.username = data['user']['username'] is String
        ? data['user']['username'] as String
        : username.trim();
  }

  /// `GET /auth/me` — 토큰이 아직 유효한지 확인하고 마이페이지 이름을 서버 값으로 맞춘다.
  Future<void> refreshProfile() async {
    _applyProfile(await _api.get('/auth/me'));
  }

  /// `PATCH /auth/me` — 마이페이지에서 실명을 입력·수정한다.
  Future<void> updateName(String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) throw ApiException('이름을 입력해주세요.');
    if (normalized.length > 40) throw ApiException('이름은 40자 이하로 입력해주세요.');
    _applyProfile(await _api.patch('/auth/me', body: {'name': normalized}));
  }

  void _applyProfile(dynamic data) {
    if (data is! Map || data['id'] is! String) {
      throw ApiException('내 정보 응답을 읽지 못했어요.');
    }
    AppSession.instance.updateProfile(
      name: data['name'] is String ? data['name'] as String : null,
      username: data['username'] is String ? data['username'] as String : null,
    );
  }

  void close() => _api.close();
}
