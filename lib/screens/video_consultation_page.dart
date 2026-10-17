import 'dart:async';

import 'package:flutter/material.dart';

import '../calls/call_engine.dart';
import '../calls/call_room.dart';
import '../calls/daily_call_factory.dart';
import '../calls/consultation_chat.dart';

enum _ExitChoice { cancel, leave }

/// The call surface stays mounted while chat floats over it.
class VideoConsultationPage extends StatefulWidget {
  const VideoConsultationPage({
    this.video,
    this.room,
    this.engine,
    this.chat,
    this.initialCameraEnabled = false,
    this.initialMicrophoneEnabled = false,
    super.key,
  });

  /// Remote video can be supplied when the call service is connected.
  final Widget? video;
  final CallRoom? room;

  /// An injected engine/chat remains owned by its caller.
  final CallEngine? engine;
  final ConsultationChat? chat;
  final bool initialCameraEnabled;
  final bool initialMicrophoneEnabled;

  @override
  State<VideoConsultationPage> createState() => _VideoConsultationPageState();
}

class _VideoConsultationPageState extends State<VideoConsultationPage>
    with WidgetsBindingObserver {
  final _messageController = TextEditingController();
  final _messageFocus = FocusNode();
  final _scroll = ScrollController();
  final _messages = <CallChatMessage>[];
  late final CallEngine? _call =
      widget.engine ??
      (widget.room == null
          ? null
          : createDailyCall(
              cameraEnabled: widget.initialCameraEnabled,
              microphoneEnabled: widget.initialMicrophoneEnabled,
            ));
  bool get _preview =>
      widget.room == null && widget.engine == null && widget.chat == null;
  Timer? _chatTimer;
  bool _polling = false;
  bool _sending = false;
  bool _serverEnded = false;
  bool _mediaClosed = false;
  bool _finishing = false;
  String? _chatError;
  bool _chatOpen = false;
  bool _ending = false;

  @override
  void initState() {
    super.initState();
    _messageFocus.addListener(_focusChanged);
    WidgetsBinding.instance.addObserver(this);
    _call?.addListener(_callChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.room != null) unawaited(_call?.connect(widget.room!));
      if (widget.chat != null) {
        unawaited(_pollChat());
        _chatTimer = Timer.periodic(
          const Duration(seconds: 3),
          (_) => _pollChat(),
        );
      }
    });
  }

  void _callChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_call?.suspendMedia());
      _chatTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_call?.resumeMedia());
      if (widget.chat != null && !_serverEnded) {
        _chatTimer?.cancel();
        unawaited(_pollChat());
        _chatTimer = Timer.periodic(
          const Duration(seconds: 3),
          (_) => _pollChat(),
        );
      }
    }
  }

  Future<void> _pollChat() async {
    if (_polling || _ending || _serverEnded || widget.chat == null) return;
    _polling = true;
    try {
      final snapshot = await widget.chat!.poll();
      if (!mounted) return;
      final existing = _messages.map((message) => message.id).toSet();
      final added = snapshot.messages
          .where((message) => existing.add(message.id))
          .toList();
      final responseIds = <String>{};
      final serverMessages = snapshot.messages
          .where((message) => responseIds.add(message.id))
          .toList();
      final pendingMessages = _messages
          .where((message) => !responseIds.contains(message.id))
          .toList();
      setState(() {
        _messages
          ..clear()
          ..addAll(serverMessages)
          ..addAll(pendingMessages);
        if (!_sending) _chatError = null;
        _serverEnded = snapshot.ended;
      });
      if (added.isNotEmpty) _scrollToLatest();
      if (snapshot.ended) {
        _chatTimer?.cancel();
        await _call?.close();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _chatError = '채팅을 갱신하지 못했어요. 다시 연결되면 자동으로 확인합니다.');
      }
    } finally {
      _polling = false;
    }
  }

  void _focusChanged() {
    if (_messageFocus.hasFocus && !_chatOpen) {
      setState(() => _chatOpen = true);
      _scrollToLatest();
    }
  }

  void _collapseChat() {
    _messageFocus.unfocus();
    setState(() => _chatOpen = false);
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty ||
        text.length > 1000 ||
        _sending ||
        _serverEnded ||
        _ending) {
      return;
    }
    if (!_preview && widget.chat == null) return;
    setState(() {
      _sending = true;
      _chatError = null;
      _chatOpen = true;
    });
    try {
      final message = _preview
          ? CallChatMessage(
              id: 'preview-${_messages.length}',
              text: text,
              local: true,
            )
          : await widget.chat!.send(text);
      if (!mounted) return;
      setState(() {
        if (!_messages.any((previous) => previous.id == message.id)) {
          _messages.add(message);
        }
        if (_messageController.text.trim() == text) _messageController.clear();
      });
      _scrollToLatest();
    } catch (_) {
      if (mounted) {
        setState(() => _chatError = '메시지를 보내지 못했어요. 입력한 내용은 유지됩니다. 다시 보내주세요.');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _end() async {
    if (_ending) return;
    _ending = true;
    final confirmed = await showDialog<_ExitChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('상담 화면을 종료할까요?'),
        content: Text(
          _preview
              ? '미리보기 메시지는 저장되지 않습니다. 실제 상담은 진행되지 않았습니다.'
              : '영상통화를 나가고 상담 결과를 기다립니다. 약사가 상담을 마무리하고 검토한 요약을 공개해요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitChoice.cancel),
            child: const Text('계속 보기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitChoice.leave),
            child: Text(_preview ? '종료' : '통화 나가기'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed == null || confirmed == _ExitChoice.cancel) {
      _ending = false;
      return;
    }
    try {
      setState(() => _finishing = true);
      await _call?.close();
      if (!mounted) return;
      setState(() => _mediaClosed = true);
      // 환자는 미디어 연결만 닫는다. 서버 종료와 요약 공개는 약사가 처리한다.
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _chatError = '통화 연결을 닫지 못했어요. 다시 시도해주세요.');
      }
    } finally {
      _ending = false;
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chatTimer?.cancel();
    _call?.removeListener(_callChanged);
    unawaited(_call?.close());
    if (widget.engine == null) _call?.dispose();
    _messageFocus.removeListener(_focusChanged);
    _messageFocus.dispose();
    _messageController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String get _callStatus {
    if (_finishing) return '상담 종료를 처리하는 중이에요.';
    if (_serverEnded) return '상담이 종료되었어요.';
    if (_mediaClosed) return '통화는 종료되었어요. 상담 종료 상태를 확인해주세요.';
    if (_call == null) return '상대방 영상과 음성은 서버 연결 후 제공됩니다.';
    if (_call.error != null) return _call.error!;
    return switch (_call.phase) {
      CallPhase.idle || CallPhase.connecting => '영상통화에 연결하는 중이에요.',
      CallPhase.connected =>
        !_call.hasRemoteParticipant
            ? '상대방 입장을 기다리고 있어요.'
            : !_call.remoteHasVideo
            ? '상대방 카메라가 꺼져 있어요. 음성으로 상담할 수 있어요.'
            : '영상통화 연결됨',
      CallPhase.disconnected => '통화 연결이 종료되었어요. 필요하면 다시 연결해주세요.',
      CallPhase.failed => '통화에 연결하지 못했어요.',
      CallPhase.leaving => '통화를 종료하는 중이에요.',
      CallPhase.unsupported => '실제 영상통화는 Android 또는 iOS 앱에서 이용해주세요.',
    };
  }

  Widget _callSurface() {
    final call = _call;
    if (call == null) {
      return const ColoredBox(
        color: Color(0xFF18201E),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                child: Icon(Icons.person_outline, size: 56),
              ),
              SizedBox(height: 20),
              Text(
                '약사 영상 연결 준비 중',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }
    final connected =
        call.phase == CallPhase.connected && !_serverEnded && !_mediaClosed;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (connected && call.remoteHasVideo)
          call.remoteVideo()
        else
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (call.phase == CallPhase.connecting)
                      const CircularProgressIndicator()
                    else
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white54,
                        size: 72,
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _callStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (!_serverEnded &&
                        !_mediaClosed &&
                        widget.room != null &&
                        (call.phase == CallPhase.failed ||
                            call.phase == CallPhase.disconnected))
                      TextButton.icon(
                        onPressed: () => call.connect(widget.room!),
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 연결'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        if (connected && call.localHasVideo)
          Positioned(
            top: 90,
            right: 12,
            width: 88,
            height: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: call.localVideo(),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _end();
    },
    child: Scaffold(
      backgroundColor: const Color(0xFF18201E),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('화상 상담'),
        actions: [
          TextButton.icon(
            onPressed: _finishing ? null : _end,
            icon: const Icon(Icons.call_end, color: Colors.red),
            label: Text(
              _finishing ? '종료 중...' : '상담 종료',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              // Never swap the video out when the composer or keyboard opens.
              Positioned.fill(
                child: GestureDetector(
                  onTap: _collapseChat,
                  behavior: HitTestBehavior.translucent,
                  child: SizedBox.expand(
                    key: const Key('consultation-video-surface'),
                    child: widget.video ?? _callSurface(),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: IgnorePointer(
                  child: Text(
                    _callStatus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                    ),
                  ),
                ),
              ),
              if (_call != null && !_serverEnded && !_mediaClosed)
                Positioned(
                  top: 44,
                  left: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x66000000),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _call.cameraEnabled ? '카메라 끄기' : '카메라 켜기',
                          onPressed:
                              _call.phase != CallPhase.connected ||
                                  _call.controlsBusy
                              ? null
                              : () => _call.setCamera(!_call.cameraEnabled),
                          icon: Icon(
                            _call.cameraEnabled
                                ? Icons.videocam
                                : Icons.videocam_off,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          tooltip: _call.microphoneEnabled
                              ? '마이크 끄기'
                              : '마이크 켜기',
                          onPressed:
                              _call.phase != CallPhase.connected ||
                                  _call.controlsBusy
                              ? null
                              : () => _call.setMicrophone(
                                  !_call.microphoneEnabled,
                                ),
                          icon: Icon(
                            _call.microphoneEnabled ? Icons.mic : Icons.mic_off,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          tooltip: '카메라 전환',
                          onPressed:
                              _call.phase != CallPhase.connected ||
                                  _call.controlsBusy ||
                                  !_call.cameraEnabled
                              ? null
                              : _call.flipCamera,
                          icon: const Icon(
                            Icons.cameraswitch,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: TextFieldTapRegion(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_chatError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            _chatError!,
                            style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (_chatOpen) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            onPressed: _collapseChat,
                            tooltip: '채팅 접기',
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0x66000000),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_messages.isNotEmpty)
                          SizedBox(
                            height: constraints.maxHeight * 0.38,
                            child: ListView.builder(
                              key: const Key('consultation-chat-messages'),
                              controller: _scroll,
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) => Align(
                                alignment: _messages[index].local
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth * 0.78,
                                  ),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _messages[index].local
                                        ? const Color(0xB3176B5B)
                                        : const Color(0x99343D39),
                                    border: Border.all(
                                      color: const Color(0x33FFFFFF),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _messages[index].text,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                      TextField(
                        enabled:
                            !_serverEnded &&
                            !_finishing &&
                            (_preview || widget.chat != null),
                        key: const Key('consultation-chat-input'),
                        controller: _messageController,
                        focusNode: _messageFocus,
                        onTap: () => setState(() => _chatOpen = true),
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: _serverEnded
                              ? '상담이 종료되었어요'
                              : _preview
                              ? '미리보기 메시지 입력'
                              : widget.chat == null
                              ? '상담 채팅 연결 준비 중'
                              : '메시지 입력',
                          hintStyle: const TextStyle(color: Colors.white70),
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0x332F3C37),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          prefixIcon: IconButton(
                            tooltip: '채팅 열기',
                            onPressed: () {
                              _messageFocus.requestFocus();
                              setState(() => _chatOpen = true);
                              _scrollToLatest();
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white70,
                            ),
                          ),
                          suffixIcon: IconButton(
                            onPressed:
                                _sending ||
                                    _serverEnded ||
                                    (!_preview && widget.chat == null)
                                ? null
                                : _send,
                            tooltip: '메시지 보내기',
                            icon: const Icon(
                              Icons.send,
                              color: Color(0xFF65D6A8),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white38),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(color: Colors.white38),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Color(0xFF65D6A8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
