import 'package:flutter/material.dart';

import 'call_engine.dart';
import 'call_room.dart';

CallEngine createDailyCall({
  bool cameraEnabled = false,
  bool microphoneEnabled = false,
}) => UnsupportedCallEngine();

class UnsupportedCallEngine extends CallEngine {
  @override
  CallPhase get phase => CallPhase.unsupported;
  @override
  String get error => '실제 영상통화는 Android 또는 iOS 앱에서 이용해주세요.';
  @override
  bool get cameraEnabled => false;
  @override
  bool get microphoneEnabled => false;
  @override
  bool get hasRemoteParticipant => false;
  @override
  bool get remoteHasVideo => false;
  @override
  bool get localHasVideo => false;
  @override
  bool get controlsBusy => false;
  @override
  Widget remoteVideo() => const SizedBox.shrink();
  @override
  Widget localVideo() => const SizedBox.shrink();
  @override
  Future<void> connect(CallRoom room) async {}
  @override
  Future<void> setCamera(bool enabled) async {}
  @override
  Future<void> setMicrophone(bool enabled) async {}
  @override
  Future<void> flipCamera() async {}
  @override
  Future<void> suspendMedia() async {}
  @override
  Future<void> resumeMedia() async {}
  @override
  Future<void> close() async {}
}
