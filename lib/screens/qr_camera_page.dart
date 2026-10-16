import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../config/app_config.dart';
import '../data/machine_qr.dart';

class QrCameraPage extends StatefulWidget {
  const QrCameraPage({this.onBack, this.onConnected, this.onScan, super.key});
  final VoidCallback? onBack;
  final VoidCallback? onConnected;
  final Future<void> Function(MachineQr)? onScan;
  @override
  State<QrCameraPage> createState() => _QrCameraPageState();
}

class _QrCameraPageState extends State<QrCameraPage>
    with WidgetsBindingObserver {
  final _controller = MobileScannerController(
    autoStart: false,
    formats: [BarcodeFormat.qrCode],
  );
  bool _started = false;
  bool _busy = false;
  String? _message;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_started || _busy) return;
    if (state == AppLifecycleState.resumed) {
      _start();
    } else if (state == AppLifecycleState.inactive) {
      _controller.stop();
    }
  }

  Future<void> _start() async {
    if (!_started) {
      setState(() => _started = true);
      await WidgetsBinding.instance.endOfFrame;
    }
    try {
      await _controller.start();
    } catch (_) {
      if (mounted) {
        setState(() => _message = '카메라를 열지 못했어요. 권한과 다른 앱의 카메라 사용 여부를 확인해주세요.');
      }
    }
  }

  Future<void> _detected(BarcodeCapture capture) async {
    if (_busy || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    setState(() => _busy = true);
    try {
      final qr = MachineQr.parse(raw);
      await _controller.stop();
      if (widget.onScan != null) {
        await widget.onScan!(qr);
        if (mounted) widget.onConnected?.call();
      } else if (mounted) {
        setState(
          () => _message = '자판기 QR을 인식했어요. 실제 기기 연결은 서버 연동 후 이용할 수 있어요.',
        );
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = '연결하지 못했어요. QR을 다시 스캔해주세요.');
    }
  }

  Future<void> _retry() async {
    setState(() {
      _busy = false;
      _message = null;
    });
    await _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF18201E),
    appBar: AppBar(
      title: const Text('QR 스캔'),
      leading: BackButton(onPressed: widget.onBack),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '자판기 화면의 QR 코드를 비춰주세요',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 24),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: _started
                  ? MobileScanner(
                      controller: _controller,
                      onDetect: _detected,
                      errorBuilder: (context, error) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            error.errorCode ==
                                    MobileScannerErrorCode.permissionDenied
                                ? '카메라 권한이 필요해요. 기기 설정에서 허용한 뒤 다시 시도해주세요.'
                                : '이 기기에서 카메라를 사용할 수 없어요.',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: Color(0xFF2A3330),
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white54,
                        size: 96,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          FilledButton.icon(
            onPressed: _retry,
            icon: Icon(_started ? Icons.refresh : Icons.camera_alt_outlined),
            label: Text(_started ? '다시 스캔' : '카메라 켜기'),
          ),
          if (AppConfig.preview.value) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: widget.onConnected,
              child: const Text('예시 자판기 연결 화면 보기'),
            ),
          ],
          const SizedBox(height: 12),
          const Text(
            '카메라는 QR 인식에만 사용합니다. QR의 유효성과 실제 연결은 서버에서 확인합니다.',
            style: TextStyle(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
