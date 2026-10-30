import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../data/auth_session.dart';
import '../widgets/pill_photo_sheet.dart';

import '../widgets/consult_header.dart';
import '../config/app_config.dart';
import '../data/app_session.dart';

/// 모약이 챗봇: 의약품 질문에 답하고, 답변마다 약사 상담으로 이어지는 버튼을 보여준다.
class ChatPage extends StatefulWidget {
  const ChatPage({
    this.client,
    this.onScanQr,
    this.onRequestConsult,
    super.key,
  });

  final http.Client? client;
  final VoidCallback? onScanQr;

  /// "약사에게 바로 상담하기" — 지금까지의 대화를 약사 상담 대기 화면으로 넘긴다.
  final VoidCallback? onRequestConsult;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final http.Client _client = widget.client ?? http.Client();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    if (widget.client == null) _client.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _sendMessage([String? text]) async {
    final question = (text ?? _messageController.text).trim();
    if (question.isEmpty || _busy) return;
    // 알약 사진 메시지는 complete가 없어 /chat 대화 기록에 들어가지 않는다.
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
      _syncSummary();
      _messageController.clear();
    });
    _scrollToBottom();
    try {
      final preview = AppConfig.preview.value && widget.client == null;
      final response = preview
          ? http.Response(
              jsonEncode(_previewAnswer),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            )
          : await _client
                .post(
                  widget.client != null && AppConfig.apiBaseUrl.isEmpty
                      ? Uri(path: '/chat')
                      : AppConfig.endpoint('/chat'),
                  headers: {
                    ...AuthSession.headers(),
                    'Content-Type': 'application/json',
                  },
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
          'recommendations': data['recommendations'],
          'complete': true,
        });
        _syncSummary();
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.remove(message);
          _syncSummary();
          _error = '$e'.replaceFirst('Exception: ', '');
          _messageController.text = question;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _attachPhotos() async {
    if (_busy) return;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: consultCream,
      builder: (_) =>
          PillPhotoSheet(client: _client, testMode: widget.client != null),
    );
    if (!mounted || result == null) return;
    setState(() {
      _messages.add({
        'role': 'user',
        'content': '알약 사진',
        'photos': result['photos'],
      });
      _messages.add({
        'role': 'assistant',
        'content': result['message'],
        'pillResult': result,
      });
    });
    _scrollToBottom();
  }

  void _explainPill(String name) {
    if (_busy) return;
    _messageController.text = '$name에 대해 설명해 주세요. 효능이랑 주의사항도 알려 주세요.';
    _sendMessage();
  }

  void _syncSummary() {
    AppSession.instance.chatSummary = _messages
        .where(
          (message) =>
              message['complete'] == true &&
              (message['role'] == 'user' || message['role'] == 'assistant'),
        )
        .map(
          (message) =>
              '${message['role'] == 'user' ? '사용자' : '모약이'}: ${message['content']}',
        )
        .join('\n');
  }

  void _showEvidence(List<dynamic> evidence) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: consultCream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _EvidenceSheet(evidence: evidence),
  );

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: consultHeaderCream,
    ),
    child: ColoredBox(
      color: consultCream,
      child: Column(
        children: [
          ConsultCreamHeader(
            title: '모약이 챗봇',
            subtitle: '의약품 정보를 쉽고 안전하게',
            onScanQr: widget.onScanQr ?? () {},
          ),
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              children: [
                const _TrustLine(),
                const SizedBox(height: 10),
                _AnswerCard(
                  answer: '안녕하세요, 전 모약이에요!\n약에 대해 궁금하신 점이 있나요?',
                  showFeedback: false,
                  sources: const [],
                  evidence: const [],
                  recommendations: const [],
                  onOpenEvidence: _showEvidence,
                ),
                for (final message in _messages) ...[
                  const SizedBox(height: 10),
                  if (message['photos'] != null)
                    PillPhotoThumbnails(photos: message['photos'])
                  else if (message['pillResult'] != null)
                    PillResultCard(
                      data: message['pillResult'],
                      onExplain: _busy ? null : _explainPill,
                    )
                  else if (message['role'] == 'user')
                    _QuestionBubble(text: message['content'] as String)
                  else ...[
                    _AnswerCard(
                      answer: message['content'] as String,
                      sources: message['sources'] is List
                          ? message['sources'] as List
                          : const [],
                      evidence: message['evidence'] is List
                          ? message['evidence'] as List
                          : const [],
                      recommendations: message['recommendations'] is List
                          ? [
                              for (final r
                                  in message['recommendations'] as List)
                                if (r is Map) r,
                            ]
                          : const [],
                      onOpenEvidence: _showEvidence,
                    ),
                    const SizedBox(height: 10),
                    _ConsultButton(onTap: widget.onRequestConsult),
                  ],
                ],
                if (_busy) ...[
                  const SizedBox(height: 10),
                  const _SystemNote(text: '답변중입니다...'),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  _SystemNote(
                    key: const Key('chat-error'),
                    text: _error!,
                    error: true,
                  ),
                ],
              ],
            ),
          ),
          _Composer(
            controller: _messageController,
            busy: _busy,
            onSend: _sendMessage,
            onAttach: _attachPhotos,
          ),
        ],
      ),
    ),
  );
}

class _TrustLine extends StatelessWidget {
  const _TrustLine();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: consultMint,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              color: consultDeepGreen,
              size: 14,
            ),
            SizedBox(width: 5),
            Text(
              '식품의약품안전처 공식 데이터 기반',
              style: TextStyle(
                color: consultDeepGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const Spacer(),
      const Text(
        '오늘 업데이트',
        style: TextStyle(color: consultMutedBrown, fontSize: 11),
      ),
    ],
  );
}

class _QuestionBubble extends StatelessWidget {
  const _QuestionBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 296),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: const BoxDecoration(
        color: consultGreen,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(5),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.45,
        ),
      ),
    ),
  );
}

class _AnswerCard extends StatefulWidget {
  const _AnswerCard({
    required this.answer,
    required this.sources,
    required this.evidence,
    required this.onOpenEvidence,
    this.recommendations = const [],
    this.showFeedback = true,
  });

  final String answer;
  final List<dynamic> sources;
  final List<dynamic> evidence;
  final ValueChanged<List<dynamic>> onOpenEvidence;

  /// 증상 추천 답변일 때 서버가 약마다 나눠준 카드 데이터. 비어 있으면 answer 원문을 그대로 보여준다.
  final List<Map> recommendations;
  final bool showFeedback;

  @override
  State<_AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<_AnswerCard> {
  bool _helpful = false;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: consultLine),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1449382F),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2C9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFB98A00),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '모약이 답변',
                style: TextStyle(
                  color: consultBrown,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: consultBeige,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: consultMutedBrown,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    '정보 안내',
                    style: TextStyle(
                      color: consultMutedBrown,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.recommendations.isEmpty)
          _FormattedAnswer(text: widget.answer)
        else
          _RecommendationAnswer(
            answer: widget.answer,
            recommendations: widget.recommendations,
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2C9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFB98A00),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '정확한 진단과 복용은 약사와 상담하세요.',
                  style: TextStyle(
                    color: consultBrown,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (widget.showFeedback || widget.evidence.isNotEmpty)
          Row(
            children: [
              if (widget.evidence.isNotEmpty) ...[
                Expanded(
                  child: _CardAction(
                    background: consultMint,
                    onTap: () => widget.onOpenEvidence(widget.evidence),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.menu_book_outlined,
                          color: consultDeepGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '원문 근거 보기 (${widget.evidence.length})',
                          style: const TextStyle(
                            color: consultDeepGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else
                const Spacer(),
              if (widget.showFeedback)
                _CardAction(
                  background: _helpful ? consultMint : consultBeige,
                  onTap: () => setState(() => _helpful = !_helpful),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up_outlined,
                        color: consultMutedBrown,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        '도움돼요',
                        style: TextStyle(
                          color: consultMutedBrown,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        Text(
          '참고 약품: ${widget.sources.isEmpty ? '없음' : widget.sources.join(', ')}',
          style: const TextStyle(color: Color(0xFF9C8F86), fontSize: 11.5),
        ),
      ],
    ),
  );
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.background,
    required this.onTap,
    required this.child,
  });

  final Color background;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 42,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(child: child),
        ),
      ),
    ),
  );
}

/// 답변의 **굵게**, 번호·불릿 목록을 그대로 살려서 보여준다.
class _FormattedAnswer extends StatelessWidget {
  const _FormattedAnswer({required this.text});

  final String text;

  static final _bullet = RegExp(r'^(?:[-•]|\d+[.)])\s+(.*)');
  static const _style = TextStyle(
    color: consultBrown,
    fontSize: 15,
    height: 1.5,
  );

  static TextSpan _inline(String line) {
    final spans = <TextSpan>[];
    final parts = line.split('**');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(
        TextSpan(
          text: parts[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
      );
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final lines = text
        .split(RegExp(r'\n+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 6),
            child: switch (_bullet.firstMatch(lines[i])) {
              final match? => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('  •  ', style: _style),
                  Expanded(
                    child: Text.rich(_inline(match.group(1)!), style: _style),
                  ),
                ],
              ),
              null => Text.rich(_inline(lines[i]), style: _style),
            },
          ),
      ],
    );
  }
}

class _ConsultButton extends StatelessWidget {
  const _ConsultButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24263C34),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: onTap ?? () {},
        style: FilledButton.styleFrom(
          backgroundColor: consultGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        icon: const Icon(Icons.medical_services_outlined, size: 20),
        label: const Text('약사에게 바로 상담하기'),
      ),
    ),
  );
}

class _SystemNote extends StatelessWidget {
  const _SystemNote({required this.text, this.error = false, super.key});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: error ? const Color(0xFFFBE7E4) : consultBeige,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: error ? const Color(0xFFC94C43) : const Color(0xFF55483F),
          fontSize: 12.5,
        ),
      ),
    ),
  );
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.busy,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: consultLine)),
    ),
    child: Row(
      children: [
        IconButton(
          key: const Key('chat-attach'),
          tooltip: '알약 사진 첨부',
          onPressed: busy ? null : onAttach,
          icon: const Icon(Icons.add),
        ),
        Expanded(
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: controller,
              maxLength: 4000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(color: consultBrown, fontSize: 13),
              decoration: InputDecoration(
                counterText: '',
                hintText: '약이나 증상을 물어보세요',
                hintStyle: const TextStyle(
                  color: consultMutedBrown,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.chat_bubble_outline,
                  color: consultMutedBrown,
                  size: 18,
                ),
                filled: true,
                fillColor: consultCream,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: consultLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: consultGreen),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          key: const Key('chat-send'),
          tooltip: '메시지 전송',
          onPressed: busy ? null : onSend,
          style: IconButton.styleFrom(
            backgroundColor: consultGreen,
            foregroundColor: Colors.white,
            fixedSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.arrow_upward, size: 20),
        ),
      ],
    ),
  );
}

/// "원문 근거 보기" — 답변에 사용된 공식 정보 목록.
class _EvidenceSheet extends StatelessWidget {
  const _EvidenceSheet({required this.evidence});

  final List<dynamic> evidence;

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.6,
    maxChildSize: 0.9,
    builder: (context, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: consultLine,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '원문 근거',
          style: TextStyle(
            color: consultBrown,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          '답변에 사용된 공식 정보',
          style: TextStyle(color: consultMutedBrown, fontSize: 12),
        ),
        const SizedBox(height: 14),
        for (final e in evidence)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: consultLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e['item_name']} · ${e['field_label']}',
                  style: const TextStyle(
                    color: consultBrown,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${e['text']}',
                  style: const TextStyle(
                    color: consultMutedBrown,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          '출처: 식품의약품안전처 e약은요 · 의약품 허가정보·DUR',
          style: TextStyle(color: Color(0xFF9C8F86), fontSize: 11),
        ),
      ],
    ),
  );
}

/// 서버 없이 화면을 확인하는 미리보기용 답변. 추천 카드 모양까지 볼 수 있게 recommendations를 채운다.
const _previewAnswer = {
  'answer':
      '[화면 미리보기] 열이 날 때 도움이 될 수 있는 약을 1가지 알려드릴게요.\n\n'
      '💊 1. 예시 해열제시럽\n'
      '· 추천 이유: 화면 확인용 예시 문장입니다. 실제 의약품 안내가 아닙니다.\n'
      '· 성분: 성분 설명이 이 자리에 표시됩니다.\n'
      '· 주의: 주의사항 한 가지가 이 자리에 표시됩니다.\n\n'
      '복용법이나 더 자세한 주의사항이 궁금한 약을 말씀해 주시면 자세히 알려드릴게요.\n'
      '정확한 진단과 복용은 약사와 상담하시기 바랍니다.',
  'sources': <String>[],
  'evidence': <Object>[],
  'recommendations': [
    {
      'rank': 1,
      'item_name': '예시 해열제시럽',
      'reason': '화면 확인용 예시 문장입니다. 실제 의약품 안내가 아닙니다.',
      'ingredient': '성분 설명이 이 자리에 표시됩니다.',
      'caution': '주의사항 한 가지가 이 자리에 표시됩니다.',
    },
  ],
};

const _recCream = Color(0xFFFFFCF0);
const _recLine = Color(0xFFEFE3BF);

/// 증상 추천 답변: 안내 문장 → 약별 카드 → 마무리 문장(초록 굵게).
/// 안전 문구와 참고 약품은 답변 카드가 따로 보여주므로 여기서는 뺀다.
class _RecommendationAnswer extends StatelessWidget {
  const _RecommendationAnswer({
    required this.answer,
    required this.recommendations,
  });

  final String answer;
  final List<Map> recommendations;

  static final _heading = RegExp(r'^\s*💊');
  static final _field = RegExp(r'^(추천 이유|성분|주의)\s*:');
  static final _bullet = RegExp(r'^[·•\-]\s*');

  /// 백엔드 parse_recommendations와 같은 규칙으로 카드 앞뒤 문장만 골라낸다.
  static ({List<String> intro, List<String> outro}) split(String answer) {
    final intro = <String>[];
    final outro = <String>[];
    var seenCard = false;
    for (final raw in answer.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (_heading.hasMatch(line)) {
        seenCard = true;
        continue;
      }
      if (!seenCard) {
        intro.add(line);
        continue;
      }
      final text = line.replaceFirst(_bullet, '');
      if (_field.hasMatch(text) ||
          text.startsWith('정확한 진단') ||
          text.startsWith('[참고')) {
        continue;
      }
      outro.add(text);
    }
    return (intro: intro, outro: outro);
  }

  @override
  Widget build(BuildContext context) {
    final parts = split(answer);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parts.intro.isNotEmpty) ...[
          _FormattedAnswer(text: parts.intro.join('\n')),
          const SizedBox(height: 12),
        ],
        for (final (i, r) in recommendations.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          _RecommendationCard(
            rank: r['rank'] is int ? r['rank'] as int : i + 1,
            name: '${r['item_name'] ?? ''}',
            reason: '${r['reason'] ?? ''}',
            ingredient: '${r['ingredient'] ?? ''}',
            caution: '${r['caution'] ?? ''}',
          ),
        ],
        if (parts.outro.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            parts.outro.join('\n'),
            style: const TextStyle(
              color: consultGreen,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.rank,
    required this.name,
    required this.reason,
    required this.ingredient,
    required this.caution,
  });

  final int rank;
  final String name;
  final String reason;
  final String ingredient;
  final String caution;

  @override
  Widget build(BuildContext context) => Container(
    key: Key('recommendation-$rank'),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
    decoration: BoxDecoration(
      color: _recCream,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _recLine, width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: consultGreen,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: consultBrown,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (reason.isNotEmpty) _RecommendationSection('✅', '추천 이유', reason),
        if (ingredient.isNotEmpty)
          _RecommendationSection('🧪', '성분', ingredient),
        if (caution.isNotEmpty) _RecommendationSection('⚠️', '주의', caution),
      ],
    ),
  );
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection(this.emoji, this.label, this.text);

  final String emoji;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$emoji $label',
          style: const TextStyle(
            color: consultMutedBrown,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: consultBrown,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

/// 사용자가 올린 알약 사진 (오른쪽 말풍선).
