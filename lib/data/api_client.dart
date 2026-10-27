/// 백엔드 JSON API 공통 처리: 주소 만들기, 오류 메시지, 서버 시간 변환.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_session.dart';

class ApiClient {
  /// [client]는 테스트에서 가짜 응답을 넣을 때 쓴다. 서버 주소 설정이 없으면
  /// 테스트용으로 상대 경로를 쓴다.
  ApiClient({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Uri uri(String path, [Map<String, String>? query]) {
    final base = !_ownsClient && AppConfig.apiBaseUrl.isEmpty
        ? Uri(path: path)
        : AppConfig.endpoint(path);
    return query == null ? base : base.replace(queryParameters: query);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 20),
  }) async => _decode(
    await _client
        .get(
          uri(path, query),
          headers: {
            ...((const {
                  '/auth/login',
                  '/auth/signup',
                  '/auth/username-available',
                  '/auth/status',
                }.contains(path))
                ? <String, String>{}
                : AuthSession.headers()),
            ...?headers,
          },
        )
        .timeout(timeout),
  );

  Future<dynamic> post(
    String path, {
    Object? body,
    Duration timeout = const Duration(seconds: 20),
  }) async => _decode(
    await _client
        .post(
          uri(path),
          headers: {
            ...((const {
                  '/auth/login',
                  '/auth/signup',
                  '/auth/username-available',
                  '/auth/status',
                }.contains(path))
                ? <String, String>{}
                : AuthSession.headers()),
            if (body != null) 'Content-Type': 'application/json',
          },
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout),
  );

  Future<dynamic> patch(String path, {required Object body}) async => _decode(
    await _client
        .patch(
          uri(path),
          headers: {
            ...AuthSession.headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20)),
  );

  /// 사진 업로드처럼 파일을 보내는 요청(`multipart/form-data`).
  Future<dynamic> postFiles(
    String path, {
    required List<http.MultipartFile> files,
    Map<String, String>? query,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final request = http.MultipartRequest('POST', uri(path, query))
      ..headers.addAll(AuthSession.headers())
      ..files.addAll(files);
    final streamed = await _client.send(request).timeout(timeout);
    return _decode(await http.Response.fromStream(streamed).timeout(timeout));
  }

  /// 서버는 실패 시 `{"detail": "한국어 메시지"}`를 준다.
  dynamic _decode(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException('서버 응답을 읽지 못했어요 (${response.statusCode}).');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        data is Map && data['detail'] is String
            ? data['detail'] as String
            : '서버 요청에 실패했어요 (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// 서버 시간은 UTC이고 끝에 `Z`가 없다. 기기 시간으로 바꾼다.
DateTime? parseServerTime(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final hasZone =
      value.endsWith('Z') || RegExp(r'[+-]\d\d:\d\d$').hasMatch(value);
  return DateTime.tryParse(hasZone ? value : '${value}Z')?.toLocal();
}
