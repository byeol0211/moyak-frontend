import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class CallChatMessage {
  const CallChatMessage({
    required this.id,
    required this.text,
    required this.local,
  });
  final String id;
  final String text;
  final bool local;
}

class ConsultationChatSnapshot {
  const ConsultationChatSnapshot(this.messages, {this.ended = false});
  final List<CallChatMessage> messages;
  final bool ended;
}

abstract class ConsultationChat {
  String? get summary;
  Future<ConsultationChatSnapshot> poll();
  Future<CallChatMessage> send(String text);
  Future<void> end();
  Future<void> cancel();
  void dispose();
}

/// Client for the existing consultation API; does not create backend services.
class ApiConsultationChat implements ConsultationChat {
  String? _summary;
  @override
  String? get summary => _summary;
  ApiConsultationChat({
    required this.consultationId,
    required this.userId,
    http.Client? client,
    this.baseUrl,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;
  final String consultationId;
  final String userId;
  final http.Client _client;
  final bool _ownsClient;
  final Uri? baseUrl;

  Uri _endpoint(String suffix) {
    final path = '/consultations/${Uri.encodeComponent(consultationId)}$suffix';
    return baseUrl?.resolve(path) ?? AppConfig.endpoint(path);
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        response.statusCode == 409
            ? '이미 종료된 상담이에요.'
            : '상담 서버 요청에 실패했어요. 다시 시도해주세요.',
      );
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  CallChatMessage _message(dynamic json) {
    if (json is! Map || json['id'] == null || json['content'] is! String) {
      throw const FormatException('채팅 응답 형식을 확인해주세요.');
    }
    return CallChatMessage(
      id: '${json['id']}',
      text: json['content'],
      local: json['sender_role'] == 'user' && '${json['sender_id']}' == userId,
    );
  }

  @override
  Future<ConsultationChatSnapshot> poll() async {
    final responses = await Future.wait([
      _client.get(_endpoint('/messages')).timeout(const Duration(seconds: 15)),
      _client.get(_endpoint('')).timeout(const Duration(seconds: 15)),
    ]);
    final messages = _decode(responses[0]);
    final status = _decode(responses[1]);
    if (messages is! List || status is! Map) {
      throw const FormatException('상담 응답 형식을 확인해주세요.');
    }
    if (status['summary'] is String) _summary = status['summary'] as String;
    return ConsultationChatSnapshot(
      messages.map(_message).toList(),
      ended: status['ended_at'] != null || status['status'] == 'cancelled',
    );
  }

  @override
  Future<CallChatMessage> send(String text) async {
    final content = text.trim();
    if (content.isEmpty || content.length > 1000) {
      throw const FormatException('메시지는 1~1000자로 입력해주세요.');
    }
    final response = await _client
        .post(
          _endpoint('/messages'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_role': 'user',
            'sender_id': userId,
            'content': content,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _message(_decode(response));
  }

  @override
  Future<void> end() async {
    final response = await _client
        .post(_endpoint('/end'))
        .timeout(const Duration(seconds: 90));
    final data = _decode(response);
    if (data is Map && data['summary'] is String) {
      _summary = data['summary'] as String;
    }
  }

  @override
  Future<void> cancel() async {
    final response = await _client
        .post(_endpoint('/cancel'))
        .timeout(const Duration(seconds: 15));
    _decode(response);
  }

  @override
  void dispose() {
    if (_ownsClient) _client.close();
  }
}
