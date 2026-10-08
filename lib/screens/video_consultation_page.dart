import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoConsultationPage extends StatefulWidget {
  const VideoConsultationPage({super.key});

  @override
  State<VideoConsultationPage> createState() => _VideoConsultationPageState();
}

class _VideoConsultationPageState extends State<VideoConsultationPage> {
  final _messageController = TextEditingController();
  bool _microphoneEnabled = true;
  bool _cameraEnabled = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
    child: Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/figma/onboarding_video_preview.png',
              fit: BoxFit.fill,
              semanticLabel: '약사와 화상 상담 중인 화면',
            ),
            Positioned(
              left: constraints.maxWidth * 0.025,
              top: constraints.maxHeight * 0.045,
              width: 40,
              height: 40,
              child: Semantics(
                button: true,
                label: '이전 화면',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.30,
              bottom: constraints.maxHeight * 0.275,
              child: Row(
                children: [
                  _CallControl(
                    icon: _microphoneEnabled
                        ? Icons.mic_none
                        : Icons.mic_off_outlined,
                    label: _microphoneEnabled ? '마이크 끄기' : '마이크 켜기',
                    background: const Color(0xFF44484B),
                    onTap: () => setState(
                      () => _microphoneEnabled = !_microphoneEnabled,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CallControl(
                    icon: _cameraEnabled
                        ? Icons.videocam_outlined
                        : Icons.videocam_off_outlined,
                    label: _cameraEnabled ? '카메라 끄기' : '카메라 켜기',
                    background: _cameraEnabled
                        ? const Color(0xFF44484B)
                        : const Color(0xFFFF3D32),
                    onTap: () => setState(() => _cameraEnabled = !_cameraEnabled),
                  ),
                  const SizedBox(width: 10),
                  _CallControl(
                    icon: Icons.videocam_outlined,
                    label: '통화 종료',
                    background: const Color(0xFF44484B),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.05,
              bottom: constraints.maxHeight * 0.14,
              width: constraints.maxWidth * 0.42,
              height: 36,
              child: Semantics(
                button: true,
                label: '채팅창 열기',
                child: GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                ),
              ),
            ),
            Positioned(
              left: constraints.maxWidth * 0.145,
              right: constraints.maxWidth * 0.16,
              bottom: constraints.maxHeight * 0.064,
              height: 38,
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  hintStyle: const TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F4F4),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Positioned(
              right: constraints.maxWidth * 0.035,
              bottom: constraints.maxHeight * 0.064,
              width: 38,
              height: 38,
              child: IconButton.filled(
                onPressed: () => _messageController.clear(),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD15C),
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.arrow_upward, size: 18),
                tooltip: '메시지 보내기',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CallControl extends StatelessWidget {
  const _CallControl({
    required this.icon,
    required this.label,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    ),
  );
}
