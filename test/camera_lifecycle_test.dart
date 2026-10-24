import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moyak/widgets/device_camera_preview.dart';

class _Camera extends CameraPlatform {
  final errors = StreamController<CameraErrorEvent>.broadcast();
  final ready = Completer<void>();
  final started = Completer<void>();
  int releases = 0;
  bool failRelease = false;
  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(
      name: 'front',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 0,
    ),
  ];
  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings? mediaSettings,
  ) async => 1;
  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {
    started.complete();
    await ready.future;
  }

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream.value(
        const CameraInitializedEvent(
          1,
          320,
          240,
          ExposureMode.auto,
          false,
          FocusMode.auto,
          false,
        ),
      );
  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      Stream.value(
        const DeviceOrientationChangedEvent(DeviceOrientation.portraitUp),
      );
  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) => errors.stream;
  @override
  Widget buildPreview(int cameraId) => const SizedBox();
  @override
  Future<void> dispose(int cameraId) async {
    releases++;
    if (failRelease) throw PlatformException(code: 'IllegalStateException');
  }
}

void main() {
  testWidgets('leaving during initialization releases the late camera', (
    tester,
  ) async {
    final original = CameraPlatform.instance;
    final camera = _Camera();
    CameraPlatform.instance = camera;
    addTearDown(() => CameraPlatform.instance = original);
    final handle = CameraPreviewHandle();
    await tester.pumpWidget(
      MaterialApp(home: DeviceCameraPreview(handle: handle)),
    );
    final start = handle.setCamera(true);
    await tester.pump();
    expect(camera.started.isCompleted, isTrue);
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
    camera.ready.complete();
    await tester.pumpAndSettle();
    await start;
    expect(camera.releases, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets('stop waits for initialization and releases only once', (
    tester,
  ) async {
    final original = CameraPlatform.instance;
    final camera = _Camera();
    CameraPlatform.instance = camera;
    addTearDown(() => CameraPlatform.instance = original);
    final handle = CameraPreviewHandle();
    await tester.pumpWidget(
      MaterialApp(home: DeviceCameraPreview(handle: handle)),
    );
    final start = handle.setCamera(true);
    await tester.pump();
    expect(camera.started.isCompleted, isTrue);
    final stop = handle.stop();
    await tester.pump();
    expect(camera.releases, 0);
    camera.ready.complete();
    await tester.pumpAndSettle();
    await start;
    await stop;
    expect(camera.releases, 1);
    expect(handle.cameraEnabled, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    handle.dispose();
  });
  testWidgets(
    'permission dialog does not cancel initialization; cleanup error is handled',
    (tester) async {
      final original = CameraPlatform.instance;
      final camera = _Camera()..failRelease = true;
      CameraPlatform.instance = camera;
      addTearDown(() => CameraPlatform.instance = original);
      final handle = CameraPreviewHandle();
      await tester.pumpWidget(
        MaterialApp(home: DeviceCameraPreview(handle: handle)),
      );
      final start = handle.setCamera(true);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      camera.ready.complete();
      await tester.pumpAndSettle();
      await start;
      expect(handle.cameraEnabled, isTrue);
      await handle.stop();
      expect(camera.releases, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      handle.dispose();
    },
  );
}
