import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_status_bar.dart';

const _scanLineColor = Color(0xFFFFD54F);
const _qrModuleColor = Color(0xFFD9E4E8);

class QrCameraPage extends StatefulWidget {
  const QrCameraPage({this.onBack, this.onConnected, super.key});

  final VoidCallback? onBack;
  final VoidCallback? onConnected;

  @override
  State<QrCameraPage> createState() => _QrCameraPageState();
}

class _QrCameraPageState extends State<QrCameraPage> {
  bool _muted = true;

  Future<void> _verifyScannedCode() async {
    final authenticated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xB83E2723),
      builder: (dialogContext) => _QrBiometricDialog(
        onCancel: () => Navigator.of(dialogContext).pop(false),
        onAuthenticate: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (authenticated == true && mounted) widget.onConnected?.call();
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
      body: SafeArea(
        child: Column(
          children: [
            const AppStatusBar(color: Colors.white),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'QR 스캔',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'QR 코드를 스캔하세요',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '자판기 화면의 QR 코드를 비추면 연동됩니다',
              style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 11),
            ),
            const SizedBox(height: 34),
            _QrCameraGuide(onTap: _verifyScannedCode),
            const Spacer(),
            IconButton.filled(
              onPressed: () => setState(() => _muted = !_muted),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF252525),
                foregroundColor: Colors.white,
                fixedSize: const Size(38, 38),
              ),
              icon: Icon(
                _muted ? Icons.mic_off_outlined : Icons.mic_none,
                size: 18,
              ),
              tooltip: _muted ? '마이크 켜기' : '마이크 끄기',
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    ),
  );
}

class _QrCameraGuide extends StatelessWidget {
  const _QrCameraGuide({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 224,
      height: 224,
      decoration: BoxDecoration(
        color: const Color(0xFF111820),
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _QrPatternPainter()),
          Align(
            alignment: const Alignment(0, -0.05),
            child: Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                border: Border.all(color: _qrModuleColor, width: 2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const CustomPaint(painter: _QrPatternPainter()),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.05),
            child: Container(
              height: 1,
              color: _scanLineColor,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QrBiometricDialog extends StatelessWidget {
  const _QrBiometricDialog({
    required this.onCancel,
    required this.onAuthenticate,
  });

  final VoidCallback onCancel;
  final VoidCallback onAuthenticate;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onAuthenticate,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBE5),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fingerprint,
                  color: Color(0xFFFFD54F),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '생체 인증이 필요합니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF3E2723),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              '기기에 등록된 지문을 인식해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8D7F79), fontSize: 11),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF0ECE9)),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8D7F79),
                  backgroundColor: const Color(0xFFF4F4F3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('취소'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _QrPatternPainter extends CustomPainter {
  const _QrPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const count = 29;
    final cell = size.width / count;
    final paint = Paint()..color = _qrModuleColor;

    bool inFinder(int x, int y, int left, int top) =>
        x >= left && x < left + 7 && y >= top && y < top + 7;

    bool finderModule(int x, int y, int left, int top) {
      final dx = x - left;
      final dy = y - top;
      return dx == 0 || dx == 6 || dy == 0 || dy == 6 ||
          (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4);
    }

    for (var y = 0; y < count; y++) {
      for (var x = 0; x < count; x++) {
        final topLeft = inFinder(x, y, 1, 1);
        final topRight = inFinder(x, y, count - 8, 1);
        final bottomLeft = inFinder(x, y, 1, count - 8);
        final dark = topLeft
            ? finderModule(x, y, 1, 1)
            : topRight
            ? finderModule(x, y, count - 8, 1)
            : bottomLeft
            ? finderModule(x, y, 1, count - 8)
            : (x * 17 + y * 29 + x * y * 3) % 11 < 5;

        if (dark) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell * 0.88, cell * 0.88),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPatternPainter oldDelegate) => false;
}
