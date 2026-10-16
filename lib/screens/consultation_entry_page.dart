import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../calls/call_room.dart';
import '../calls/consultation_chat.dart';

import '../widgets/device_camera_preview.dart';
import 'video_consultation_page.dart';

class ConsultationEntryPage extends StatefulWidget {
  const ConsultationEntryPage({
    required this.onBack,
    required this.onScanQr,
    required this.onEnd,
    this.room,
    this.chat,
    super.key,
  });
  final VoidCallback onBack;
  final VoidCallback onScanQr;
  final VoidCallback onEnd;
  final CallRoom? room;
  final ConsultationChat? chat;

  @override
  State<ConsultationEntryPage> createState() => _ConsultationEntryPageState();
}

class _ConsultationEntryPageState extends State<ConsultationEntryPage> {
  final _camera = CameraPreviewHandle();
  bool _entering = false;

  Future<void> _enter([CallRoom? testRoom]) async {
    if (_entering) return;
    setState(() => _entering = true);
    try {
      final cameraEnabled = _camera.cameraEnabled;
      final microphoneEnabled = _camera.microphoneEnabled;
      await _camera.stop();
      if (!mounted) return;
      final ended = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VideoConsultationPage(
            initialCameraEnabled: cameraEnabled,
            initialMicrophoneEnabled: microphoneEnabled,
            room: testRoom ?? widget.room,
            chat: testRoom == null ? widget.chat : null,
          ),
        ),
      );
      if (mounted && ended == true) widget.onEnd();
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  Future<void> _testRoom() async {
    final url = TextEditingController();
    final token = TextEditingController();
    String? error;
    final room = await showDialog<CallRoom>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('Daily 테스트 방 입장'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '이미 만들어진 방 주소와 필요한 입장 토큰을 입력하세요. 서버 API 키를 입력하지 마세요.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Daily 방 주소',
                    hintText: 'https://your-domain.daily.co/room',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: token,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(labelText: '입장 토큰 (선택)'),
                ),
                if (error != null)
                  Text(error!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                try {
                  final room = CallRoom(
                    roomUrl: url.text,
                    token: token.text.trim().isEmpty ? null : token.text.trim(),
                  );
                  Navigator.pop(dialogContext, room);
                } on FormatException catch (failure) {
                  update(() => error = failure.message);
                }
              },
              child: const Text('입장'),
            ),
          ],
        ),
      ),
    );
    // Wait for the closing dialog animation before releasing field controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    url.dispose();
    token.dispose();
    if (room != null && mounted) await _enter(room);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) widget.onBack();
    },
    child: ColoredBox(
      color: const Color(0xFF18201E),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    tooltip: '이전 화면',
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      '화상 상담 입장',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onScanQr,
                    tooltip: 'QR 스캔',
                    icon: const Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    '입장 전 화면과 소리를 확인해주세요',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  DeviceCameraPreview(handle: _camera),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => SystemSound.play(SystemSoundType.click),
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('스피커 테스트'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.room == null
                        ? '실제 화상 상담은 서버의 상담방 연결 후 제공됩니다. 지금은 통화 화면과 메시지 입력 흐름을 확인할 수 있어요.'
                        : '입장하면 카메라·마이크 권한을 확인하고 상담방에 연결합니다.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _entering ? null : () => _enter(),
                    icon: const Icon(Icons.videocam_outlined),
                    label: Text(
                      _entering
                          ? '입장 준비 중...'
                          : widget.room == null
                          ? '통화 화면 미리보기'
                          : '화상 상담 입장하기',
                    ),
                  ),
                  if (kDebugMode)
                    TextButton(
                      onPressed: _entering ? null : _testRoom,
                      child: const Text('개발용 Daily 테스트 방 연결'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
