import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 입장 전 카메라·마이크 상태. [DeviceCameraPreview]가 값을 채우고,
/// 화면의 스위치들이 이 값을 보고 켜고 끈다.
///
/// Local preview only; no video is recorded or sent to a server.
class CameraPreviewHandle extends ChangeNotifier {
  Future<void> Function()? _stop;
  Future<void> Function(bool)? _setCamera;
  Future<void> Function(bool)? _setMicrophone;

  bool _cameraEnabled = false;
  bool _microphoneEnabled = false;
  bool _busy = false;
  String? _error;

  bool get cameraEnabled => _cameraEnabled;
  bool get microphoneEnabled => _microphoneEnabled;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> setCamera(bool enabled) async => _setCamera?.call(enabled);
  Future<void> setMicrophone(bool enabled) async =>
      _setMicrophone?.call(enabled);

  Future<void> stop() async {
    await _stop?.call();
  }

  void _update({
    required bool cameraEnabled,
    required bool microphoneEnabled,
    required bool busy,
    required String? error,
  }) {
    if (_cameraEnabled == cameraEnabled &&
        _microphoneEnabled == microphoneEnabled &&
        _busy == busy &&
        _error == error) {
      return;
    }
    _cameraEnabled = cameraEnabled;
    _microphoneEnabled = microphoneEnabled;
    _busy = busy;
    _error = error;
    // 빌드 중에 바뀌면(화면 전환 등) 다음 프레임에 알린다.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }
}

/// 어두운 카메라 미리보기 상자. [simulated]이면 권한을 요청하지 않고
/// 켜고 끄는 모양만 보여준다(미리보기 모드).
class DeviceCameraPreview extends StatefulWidget {
  const DeviceCameraPreview({this.handle, this.simulated = false, super.key});
  final CameraPreviewHandle? handle;
  final bool simulated;
  @override
  State<DeviceCameraPreview> createState() => _DeviceCameraPreviewState();
}

const _boxColor = Color(0xFF29251F);
const _chipColor = Color(0xFF40392E);
const _accent = Color(0xFFFFD54F);
const _roundButton = Color(0xFFF1E1BB);
const _roundIcon = Color(0xFF50462A);
const _placeholder = Color(0xFFA9A8A5);

class _DeviceCameraPreviewState extends State<DeviceCameraPreview>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _lens = 0;
  bool _busy = false;
  bool _audio = false;
  bool _requested = false;
  bool _simulatedCamera = false;
  String? _error;
  int _generation = 0;
  bool _visible = true;
  Future<void>? _initialization;

  bool get _cameraOn =>
      widget.simulated ? _simulatedCamera : _controller != null;

  void _publish() => widget.handle?._update(
    cameraEnabled: _cameraOn,
    microphoneEnabled: _audio,
    busy: _busy,
    error: _error,
  );

  void _setState(VoidCallback fn) {
    setState(fn);
    _publish();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    if (_visible == visible) return;
    _visible = visible;
    if (widget.simulated) return;
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
    final handle = widget.handle;
    if (handle == null) return;
    handle._stop = () async {
      _requested = false;
      await _stop();
      await _initialization;
    };
    handle._setCamera = _setCamera;
    handle._setMicrophone = _setMicrophone;
    _publish();
  }

  Future<void> _setCamera(bool enabled) async {
    if (widget.simulated) {
      _setState(() => _simulatedCamera = enabled);
    } else if (enabled) {
      await _start();
    } else {
      _requested = false;
      await _stop();
    }
  }

  Future<void> _setMicrophone(bool enabled) async {
    _setState(() => _audio = enabled);
    // 카메라가 켜져 있으면 마이크 설정을 반영해 다시 연결한다.
    if (!widget.simulated && _controller != null) await _start();
  }

  void _switchCamera() {
    if (widget.simulated || _busy) return;
    _lens++;
    if (_controller != null) _start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.simulated) return;
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
    if (mounted) _setState(() => _busy = false);
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
    _setState(() {
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
      _setState(() => _controller = next);
    } catch (_) {
      await next?.dispose();
      if (mounted && generation == _generation) {
        _setState(
          () => _error =
              '카메라·마이크 권한 또는 기기 지원 여부를 확인해주세요. 권한을 차단했다면 기기 설정에서 허용해주세요.',
        );
      }
    } finally {
      if (mounted && generation == _generation) _setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    widget.handle?._stop = null;
    widget.handle?._setCamera = null;
    widget.handle?._setMicrophone = null;
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final cameraOn = _cameraOn;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 1.16,
        child: ColoredBox(
          color: _boxColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (controller != null)
                Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: CameraPreview(controller),
                  ),
                )
              else
                Center(
                  child: _busy
                      ? const CircularProgressIndicator(color: _accent)
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cameraOn
                                  ? Icons.videocam_outlined
                                  : Icons.videocam_off_outlined,
                              size: 56,
                              color: const Color(0xFF9D9B98),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.simulated
                                  ? (cameraOn
                                        ? '카메라 켜짐 · 실제 영상은 표시하지 않아요'
                                        : '실제 카메라 영상은 표시하지 않아요')
                                  : '카메라가 꺼져 있어요',
                              style: const TextStyle(
                                color: _placeholder,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              Positioned(
                left: 16,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _chipColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: _accent, size: 12),
                      SizedBox(width: 8),
                      Text(
                        '상담 화면 미리보기',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.simulated || _cameras.length > 1)
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    tooltip: '카메라 전환',
                    onPressed: _busy ? null : _switchCamera,
                    icon: const Icon(
                      Icons.cameraswitch_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 18,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundToggle(
                      icon: cameraOn
                          ? Icons.videocam_outlined
                          : Icons.videocam_off_outlined,
                      tooltip: cameraOn ? '카메라 끄기' : '카메라 켜기',
                      onTap: _busy ? null : () => _setCamera(!cameraOn),
                    ),
                    const SizedBox(width: 16),
                    _RoundToggle(
                      icon: _audio ? Icons.mic_none : Icons.mic_off_outlined,
                      tooltip: _audio ? '마이크 끄기' : '마이크 켜기',
                      onTap: _busy ? null : () => _setMicrophone(!_audio),
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
}

class _RoundToggle extends StatelessWidget {
  const _RoundToggle({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: _roundButton,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: _roundIcon, size: 22),
        ),
      ),
    ),
  );
}
