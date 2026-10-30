import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../data/auth_session.dart';

/// `GET /consultations/{id}/session` 응답 중 환자 화면에 필요한 값.
class RecordingConsentState {
  const RecordingConsentState({
    required this.userConsented,
    required this.pharmacistConsented,
    required this.ended,
  });

  factory RecordingConsentState.fromJson(Map json) => RecordingConsentState(
    userConsented: json['user_consent_at'] != null,
    pharmacistConsented: json['pharmacist_consent_at'] != null,
    ended: json['ended_at'] != null,
  );

  final bool userConsented;
  final bool pharmacistConsented;
  final bool ended;

  bool get bothConsented => userConsented && pharmacistConsented;
}

/// 상담 음성 기록·AI 요약 동의. 앱은 동의만 보내고 환자 기기 녹음은 하지 않는다.
abstract class RecordingConsent {
  /// 약사가 아직 상담을 연결(배정)하지 않았으면 null.
  Future<RecordingConsentState?> status();
  Future<RecordingConsentState> consent();
  void dispose();
}

class ApiRecordingConsent implements RecordingConsent {
  ApiRecordingConsent({
    required this.consultationId,
    required this.userId,
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String consultationId;
  final String userId;
  final http.Client _client;
  final bool _ownsClient;

  Uri _endpoint(String suffix) {
    final path = '/consultations/${Uri.encodeComponent(consultationId)}$suffix';
    return !_ownsClient && AppConfig.apiBaseUrl.isEmpty
        ? Uri(path: path)
        : AppConfig.endpoint(path);
  }

  /// 로그인 토큰이 있으면 Bearer, 게스트면 서버의 팀 방식 신원 헤더를 쓴다.
  Map<String, String> _headers() {
    // headers() rejects expired credentials; only a session with no token is
    // allowed to use the guest identity. Expiry must not downgrade authentication.
    final authenticatedHeaders = AuthSession.headers();
    return authenticatedHeaders.isNotEmpty
        ? authenticatedHeaders
        : {
            'X-Moyak-User-Id': Uri.encodeComponent(userId),
            'X-Moyak-Role': 'user',
          };
  }

  RecordingConsentState _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        response.statusCode == 401
            ? '로그인이 만료되었어요. 로그아웃 후 다시 로그인해주세요.'
            : response.statusCode == 409
            ? '이미 종료되었거나 약사가 연결하지 않은 상담이에요.'
            : '동의 상태를 확인하지 못했어요. 다시 시도해주세요.',
      );
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map) throw const FormatException('동의 응답 형식을 확인해주세요.');
    return RecordingConsentState.fromJson(data);
  }

  @override
  Future<RecordingConsentState?> status() async {
    final response = await _client
        .get(_endpoint('/session'), headers: _headers())
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 409) return null;
    return _decode(response);
  }

  @override
  Future<RecordingConsentState> consent() async {
    final response = await _client
        .post(_endpoint('/session/consent'), headers: _headers())
        .timeout(const Duration(seconds: 15));
    return _decode(response);
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
