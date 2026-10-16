import 'package:flutter/material.dart';

import 'call_room.dart';

enum CallPhase {
  idle,
  connecting,
  connected,
  disconnected,
  failed,
  leaving,
  unsupported,
}

/// Media transport boundary. Backend consultation/chat APIs are separate.
abstract class CallEngine extends ChangeNotifier {
  CallPhase get phase;
  String? get error;
  bool get cameraEnabled;
  bool get microphoneEnabled;
  bool get hasRemoteParticipant;
  bool get remoteHasVideo;
  bool get localHasVideo;
  bool get controlsBusy;
  Widget remoteVideo();
  Widget localVideo();
  Future<void> connect(CallRoom room);
  Future<void> setCamera(bool enabled);
  Future<void> setMicrophone(bool enabled);
  Future<void> flipCamera();
  Future<void> suspendMedia();
  Future<void> resumeMedia();
  Future<void> close();
}
