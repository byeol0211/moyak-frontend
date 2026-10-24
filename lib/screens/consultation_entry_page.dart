import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../calls/call_room.dart';
import '../calls/consultation_chat.dart';

import '../config/app_config.dart';
import '../widgets/device_camera_preview.dart';
import '../widgets/pharmacist_theme.dart';
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
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = AppConfig.preview.value;
    String state(bool on) => '${on ? '켜짐' : '꺼짐'}${preview ? ' · UI 예시' : ''}';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: pharmHeaderBg,
        ),
        child: ColoredBox(
          color: pharmPageBg,
          child: Column(
            children: [
              PharmacistHeader(
                title: '화상 상담 입장',
                subtitle: '입장 전 화면과 소리를 확인해 주세요',
                onScanQr: widget.onScanQr,
                onBack: widget.onBack,
              ),
              Expanded(
                child: ListenableBuilder(
                  listenable: _camera,
                  builder: (context, _) => ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (preview) ...[
                        const Center(child: DemoModeChip()),
                        const SizedBox(height: 14),
                      ],
                      DeviceCameraPreview(handle: _camera, simulated: preview),
                      const SizedBox(height: 16),
                      if (preview)
                        const _EntryNotice(
                          warning: true,
                          text: '화면 설정만 시연해요. 카메라·마이크 권한을 요청하거나 실제로 연결하지 않습니다.',
                        )
                      else if (_camera.error != null)
                        _EntryNotice(warning: true, text: _camera.error!)
                      else
                        const _EntryNotice(
                          text: '기기 미리보기이며 영상과 음성은 전송·녹화되지 않습니다.',
                        ),
                      const SizedBox(height: 16),
                      _DeviceToggleCard(
                        icon: Icons.videocam_outlined,
                        title: '카메라',
                        status: _camera.busy
                            ? '확인 중...'
                            : state(_camera.cameraEnabled),
                        value: _camera.cameraEnabled,
                        onChanged: _camera.busy ? null : _camera.setCamera,
                      ),
                      const SizedBox(height: 12),
                      _DeviceToggleCard(
                        icon: Icons.mic_none,
                        title: '마이크',
                        status: state(_camera.microphoneEnabled),
                        value: _camera.microphoneEnabled,
                        onChanged: _camera.busy ? null : _camera.setMicrophone,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.volume_up_outlined),
                        label: const Text('스피커 테스트'),
                        onPressed: () => SystemSound.play(SystemSoundType.click),
                      ),
                      const SizedBox(height: 20),
                      _PharmacistRoomRow(
                        description: preview
                            ? '화면 예시 · 실제 약사 연결 없음'
                            : widget.room == null
                            ? '상담방을 준비하고 있어요'
                            : '약사가 입장하면 자동으로 연결돼요',
                        ready: !preview && widget.room != null,
                      ),
                      const SizedBox(height: 16),
                      PharmacistPrimaryButton(
                        label: _entering ? '입장 준비 중...' : '화상 상담 입장하기',
                        icon: Icons.videocam_outlined,
                        onPressed: _entering ? null : () => _enter(),
                      ),
                      if (kDebugMode)
                        TextButton(
                          onPressed: _entering ? null : _testRoom,
                          child: const Text('개발용 Daily 테스트 방 연결'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryNotice extends StatelessWidget {
  const _EntryNotice({required this.text, this.warning = false});

  final String text;
  final bool warning;

  static const _warningColor = Color(0xFFD96B55);

  @override
  Widget build(BuildContext context) {
    final color = warning ? _warningColor : pharmGreen;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFEEE8) : pharmMint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: warning ? const Color(0xFFF3E1D9) : const Color(0xFFDBE5DC),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.info_outline : Icons.shield_outlined,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 14, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceToggleCard extends StatelessWidget {
  const _DeviceToggleCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
    decoration: pharmWhiteCard,
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: pharmMint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: pharmGreen, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: pharmBrown,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: const TextStyle(color: pharmMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: pharmGreen,
          inactiveThumbColor: const Color(0xFF7D7667),
          inactiveTrackColor: const Color(0xFFEDE5D8),
          trackOutlineColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.transparent
                : const Color(0xFF7D7667),
          ),
        ),
      ],
    ),
  );
}

class _PharmacistRoomRow extends StatelessWidget {
  const _PharmacistRoomRow({required this.description, required this.ready});

  final String description;
  final bool ready;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        const Icon(Icons.person_outline, color: pharmGreen, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '약사 상담실',
                style: TextStyle(
                  color: pharmBrown,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(color: pharmMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: pharmMint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.circle, color: pharmGreen, size: 10),
              const SizedBox(width: 8),
              Text(
                ready ? '연결 준비됨' : '준비 중',
                style: const TextStyle(
                  color: pharmGreen,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
