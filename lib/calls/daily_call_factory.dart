import 'call_engine.dart';
import 'daily_call_stub.dart'
    if (dart.library.io) 'daily_call_native.dart'
    as implementation;

CallEngine createDailyCall({
  bool cameraEnabled = false,
  bool microphoneEnabled = false,
}) => implementation.createDailyCall(
  cameraEnabled: cameraEnabled,
  microphoneEnabled: microphoneEnabled,
);
