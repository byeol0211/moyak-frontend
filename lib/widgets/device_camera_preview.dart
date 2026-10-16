import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Local preview only; no video is recorded or sent to a server.
class CameraPreviewHandle {
  Future<void> Function()? _stop;
  bool Function()? _cameraEnabled;
  bool Function()? _microphoneEnabled;
  bool get cameraEnabled => _cameraEnabled?.call() ?? false;
  bool get microphoneEnabled => _microphoneEnabled?.call() ?? false;
  Future<void> stop() async {
    await _stop?.call();
  }
}

class DeviceCameraPreview extends StatefulWidget {
  const DeviceCameraPreview({this.handle, super.key});
  final CameraPreviewHandle? handle;
  @override
  State<DeviceCameraPreview> createState() => _DeviceCameraPreviewState();
}

class _DeviceCameraPreviewState extends State<DeviceCameraPreview>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _lens = 0;
  bool _busy = false;
  bool _audio = false;
  bool _requested = false;
  String? _error;
  int _generation = 0;
  bool _visible = true;
  Future<void>? _initialization;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (_visible == visible) return;
    _visible = visible;
    if (!visible) {
      _stop();
    } else if (_requested) {
      _start();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.handle?._stop = () async {
      _requested = false;
      await _stop();
      await _initialization;
    };
    widget.handle?._cameraEnabled = () => _controller != null;
    widget.handle?._microphoneEnabled = () => _audio;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _stop();
    } else if (state == AppLifecycleState.resumed && _requested && _visible) {
      _start();
    }
  }

  Future<void> _stop() async {
    _generation++;
    final controller = _controller;
    _controller = null;
    if (mounted) setState(() => _busy = false);
    await controller?.dispose();
  }

  Future<void> _start() {
    if (_busy) return _initialization ?? Future<void>.value();
    return _initialization = _initialize();
  }

  Future<void> _initialize() async {
    if (_busy || !_visible) return;
    _requested = true;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    final oldController = _controller;
    _controller = null;
    await oldController?.dispose();
    CameraController? next;
    try {
      _cameras = await availableCameras();
      if (!mounted || generation != _generation) return;
      if (_cameras.isEmpty) {
        throw CameraException('NoCamera', '사용 가능한 카메라가 없어요.');
      }
      _lens %= _cameras.length;
      next = CameraController(
        _cameras[_lens],
        ResolutionPreset.medium,
        enableAudio: _audio,
      );
      await next.initialize();
      if (!mounted || generation != _generation) {
        await next.dispose();
        return;
      }
      setState(() => _controller = next);
    } catch (_) {
      await next?.dispose();
      if (mounted && generation == _generation) {
        setState(
          () => _error =
              '카메라·마이크 권한 또는 기기 지원 여부를 확인해주세요. 권한을 차단했다면 기기 설정에서 허용해주세요.',
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    widget.handle?._stop = null;
    widget.handle?._cameraEnabled = null;
    widget.handle?._microphoneEnabled = null;
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: const Color(0xFF2A3330),
              child: controller != null
                  ? Center(
                      child: AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
                    )
                  : Center(
                      child: _busy
                          ? const CircularProgressIndicator()
                          : const Icon(
                              Icons.videocam_off_outlined,
                              size: 60,
                              color: Colors.white54,
                            ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.orangeAccent)),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      if (controller == null) {
                        await _start();
                      } else {
                        _requested = false;
                        await _stop();
                      }
                    },
              icon: Icon(
                controller == null ? Icons.videocam : Icons.videocam_off,
              ),
              label: Text(controller == null ? '카메라 켜기' : '카메라 끄기'),
            ),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _audio = !_audio);
                      if (controller != null) await _start();
                    },
              icon: Icon(_audio ? Icons.mic : Icons.mic_off),
              label: Text(_audio ? '마이크 사용' : '마이크 사용 안 함'),
            ),
            if (_cameras.length > 1)
              IconButton(
                tooltip: '카메라 전환',
                onPressed: _busy
                    ? null
                    : () {
                        _lens++;
                        _start();
                      },
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
              ),
          ],
        ),
        const Text(
          '기기 미리보기이며 영상과 음성은 전송·녹화되지 않습니다.',
          style: TextStyle(color: Colors.white60, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
