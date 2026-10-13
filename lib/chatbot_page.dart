import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'consultation_page.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key, this.client});
  final http.Client? client;
  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  late final http.Client _client = widget.client ?? http.Client();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  bool _busy = false;
  String? _error;

  void _bottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _busy) return;
    final history = _messages.where((m) => m['complete'] == true).toList();
    final recent = history
        .skip(history.length > 20 ? history.length - 20 : 0)
        .map((m) => {'role': m['role'], 'content': m['content']})
        .toList();
    final message = <String, dynamic>{'role': 'user', 'content': question};
    setState(() {
      _busy = true;
      _error = null;
      _messages.add(message);
      _input.clear();
    });
    _bottom();
    try {
      const base = String.fromEnvironment('API_BASE_URL');
      final uri = (base.isEmpty ? Uri.base : Uri.parse(base)).resolve('/chat');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'question': question, 'history': recent}),
          )
          .timeout(const Duration(seconds: 90));
      dynamic data;
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        throw Exception('서버 응답을 읽지 못했습니다 (${response.statusCode}).');
      }
      if (response.statusCode != 200) {
        throw Exception(
          data is Map && data['detail'] is String
              ? data['detail']
              : '요청에 실패했습니다 (${response.statusCode}).',
        );
      }
      if (data['answer'] is! String) throw Exception('답변 형식이 올바르지 않습니다.');
      if (!mounted) return;
      setState(() {
        message['complete'] = true;
        _messages.add({
          'role': 'assistant',
          'content': data['answer'],
          'sources': data['sources'],
          'evidence': data['evidence'],
          'complete': true,
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e'.replaceFirst('Exception: ', '');
          _input.text = question;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _bottom();
      }
    }
  }

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFF0B4),
            child: Icon(
              Icons.medical_services_outlined,
              color: Color(0xFFF1C744),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '모약이 · AI 챗봇',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ConsultationPage()),
            ),
            child: const Text('약사 상담'),
          ),
        ],
      ),
      const Divider(),
      Expanded(
        child: ListView(
          controller: _scroll,
          children: [
            _bubble('안녕하세요! 궁금한 약품이나 증상을 입력해주세요.', false),
            for (final m in _messages) ...[
              _bubble(m['content'] as String, m['role'] == 'user'),
              if (m['evidence'] is List && (m['evidence'] as List).isNotEmpty)
                ExpansionTile(
                  title: const Text('답변 근거 보기'),
                  children: [
                    for (final e in m['evidence'])
                      ListTile(
                        title: Text('${e['item_name']} · ${e['field_label']}'),
                        subtitle: Text('${e['text']}'),
                      ),
                  ],
                ),
              if (m['sources'] is List && (m['sources'] as List).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('참고: ${(m['sources'] as List).join(', ')}'),
                ),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('약품 정보를 확인하고 있어요…'),
                  ],
                ),
              ),
          ],
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _error!,
            key: const Key('chat-error'),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _input,
              maxLength: 4000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: '메시지를 입력하세요...',
                counterText: '',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          IconButton(
            key: const Key('chat-send'),
            tooltip: '메시지 전송',
            onPressed: _busy ? null : _send,
            icon: const Icon(Icons.arrow_upward),
            color: const Color(0xFFB88B00),
          ),
        ],
      ),
    ],
  );

  Widget _bubble(String text, bool user) => Align(
    alignment: user ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(15),
      constraints: const BoxConstraints(maxWidth: 500),
      decoration: BoxDecoration(
        color: user ? const Color(0xFFFFF0B4) : Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SelectableText(text),
    ),
  );
}
