import 'dart:async';
import 'dart:io';

import 'package:daily_flutter/daily_flutter.dart' as daily;
import 'package:flutter/material.dart';

import 'call_engine.dart';
import 'call_room.dart';
import 'daily_call_stub.dart';

CallEngine createDailyCall({
  bool cameraEnabled = false,
  bool microphoneEnabled = false,
}) => Platform.isAndroid || Platform.isIOS
    ? DailyCallEngine(
        cameraEnabled: cameraEnabled,
        microphoneEnabled: microphoneEnabled,
      )
    : UnsupportedCallEngine();

class DailyCallEngine extends CallEngine {
  DailyCallEngine({
    bool cameraEnabled = false,
    bool microphoneEnabled = false,
    Future<daily.CallClient> Function()? createClient,
  }) : _createClient = createClient ?? daily.CallClient.create,
       _camera = cameraEnabled,
       _desiredCamera = cameraEnabled,
       _microphone = microphoneEnabled,
       _desiredMicrophone = microphoneEnabled;
  daily.CallClient? _client;
  final Future<daily.CallClient> Function() _createClient;
  StreamSubscription<daily.Event>? _events;
  final _remoteView = daily.VideoViewController();
  final _localView = daily.VideoViewController();
  daily.Participant? _remote;
  daily.Participant? _local;
  CallPhase _phase = CallPhase.idle;
  String? _error;
  bool _camera;
  bool _microphone;
  bool _desiredCamera;
  bool _desiredMicrophone;
  Future<void> _deviceQueue = Future<void>.value();
  Future<void> _renderQueue = Future<void>.value();
  Future<void>? _connectTask;
  bool _busy = false;
  bool _connecting = false;
  bool _suspended = false;
  bool _disposed = false;
  bool _closed = false;
  int _generation = 0;
  Future<void>? _closing;

  @override
  CallPhase get phase => _phase;
  @override
  String? get error => _error;
  @override
  bool get cameraEnabled => _camera;
  @override
  bool get microphoneEnabled => _microphone;
  @override
  bool get hasRemoteParticipant => _remote != null;
  @override
  bool get remoteHasVideo => _remote?.media?.camera.track != null;
  @override
  bool get localHasVideo => _local?.media?.camera.track != null;
  @override
  bool get controlsBusy => _busy;
  void _changed() {
    if (!_disposed && !_closed) notifyListeners();
  }

  @override
  Widget remoteVideo() =>
      daily.VideoView(controller: _remoteView, fit: daily.VideoViewFit.cover);
  @override
  Widget localVideo() =>
      daily.VideoView(controller: _localView, fit: daily.VideoViewFit.cover);

  @override
  Future<void> connect(CallRoom room) {
    if (_closed) return Future<void>.value();
    if (_connecting) return _connectTask ?? Future<void>.value();
    return _connectTask = _connect(room);
  }

  Future<void> _connect(CallRoom room) async {
    if (_connecting || _closed) return;
    _connecting = true;
    final generation = ++_generation;
    _phase = CallPhase.connecting;
    _error = null;
    _changed();
    try {
      await _release();
      if (_closed || generation != _generation) return;
      final client = await _createClient();
      if (_closed || generation != _generation) {
        await client.dispose();
        return;
      }
      _client = client;
      _events = client.events.listen(
        (event) {
          if (_closed || generation != _generation) return;
          if (event is daily.CallStateUpdatedEvent) {
            _phase = switch (event.stateData.state) {
              daily.CallState.joined => CallPhase.connected,
              daily.CallState.joining => CallPhase.connecting,
              daily.CallState.leaving => CallPhase.leaving,
              daily.CallState.left => CallPhase.disconnected,
              _ => _phase,
            };
          } else if (event is daily.InputsUpdatedEvent && !_suspended) {
            _camera = event.inputs.camera.isEnabled;
            _microphone = event.inputs.microphone.isEnabled;
          } else if (event is daily.ErrorEvent) {
            _error = '통화 연결 또는 장치 사용에 문제가 발생했어요. 권한과 네트워크를 확인해주세요.';
          }
          if (event is daily.ParticipantJoinedEvent ||
              event is daily.ParticipantUpdatedEvent ||
              event is daily.ParticipantLeftEvent) {
            unawaited(_syncParticipants(client, generation));
          }
          _changed();
        },
        onError: (Object _) {
          if (!_closed && generation == _generation) {
            _phase = CallPhase.failed;
            _error = '통화 연결이 끊어졌어요. 다시 연결해주세요.';
            _changed();
          }
        },
      );
      await client.setUsername(room.displayName);
      if (_closed || generation != _generation) return;
      await client
          .join(
            url: room.url,
            token: room.token,
            clientSettings: daily.ClientSettingsUpdate.set(
              inputs: daily.InputSettingsUpdate.set(
                camera: daily.CameraInputSettingsUpdate.set(
                  isEnabled: daily.BoolUpdate.set(
                    _desiredCamera && !_suspended,
                  ),
                ),
                microphone: daily.MicrophoneInputSettingsUpdate.set(
                  isEnabled: daily.BoolUpdate.set(
                    _desiredMicrophone && !_suspended,
                  ),
                ),
              ),
            ),
          )
          .timeout(const Duration(seconds: 45));
      if (_closed || generation != _generation) return;
      if (_suspended) {
        await client.setInputsEnabled(camera: false, microphone: false);
      }
      _phase = CallPhase.connected;
      await _syncParticipants(client, generation);
      _changed();
    } catch (_) {
      if (!_closed && generation == _generation) {
        _phase = CallPhase.failed;
        _error = '입장하지 못했어요. 상담방 주소·입장 권한·카메라와 마이크 권한·네트워크를 확인하고 다시 시도해주세요.';
        await _release();
        _changed();
      }
    } finally {
      _connecting = false;
    }
  }

  Future<void> _syncParticipants(daily.CallClient client, int generation) {
    final next = _renderQueue.then(
      (_) => _updateParticipants(client, generation),
    );
    _renderQueue = next.catchError((Object _) {});
    return _renderQueue;
  }

  Future<void> _updateParticipants(
    daily.CallClient client,
    int generation,
  ) async {
    if (_closed || generation != _generation || !identical(_client, client)) {
      return;
    }
    final participants = client.participants;
    _local = participants.local;
    if (_local?.media?.camera.state == daily.MediaState.blocked ||
        _local?.media?.microphone.state == daily.MediaState.blocked) {
      _error = '카메라 또는 마이크 권한이 차단되어 있어요. 기기 설정에서 허용해주세요.';
    }
    final remotes = participants.remote.values;
    _remote =
        remotes.where((p) => p.media?.camera.track != null).firstOrNull ??
        remotes.firstOrNull;
    try {
      await _remoteView.setTrack(_remote?.media?.camera.track);
      if (_closed || generation != _generation) return;
      await _localView.setTrack(_local?.media?.camera.track);
    } catch (_) {
      // A track may disappear between participant and renderer updates.
    }
    _changed();
  }

  Future<void> _control(Future<void> Function(daily.CallClient) action) async {
    final client = _client;
    if (_closed || _busy || client == null || phase != CallPhase.connected) {
      return;
    }
    _busy = true;
    _error = null;
    _changed();
    try {
      await _device(client, () => action(client));
    } catch (_) {
      _error = '장치를 변경하지 못했어요. 카메라·마이크 권한을 확인해주세요.';
    } finally {
      _busy = false;
      _changed();
    }
  }

  @override
  Future<void> setCamera(bool enabled) => _control((client) async {
    await client.setInputsEnabled(camera: enabled && !_suspended);
    _camera = enabled;
    _desiredCamera = enabled;
  });
  @override
  Future<void> setMicrophone(bool enabled) => _control((client) async {
    await client.setInputsEnabled(microphone: enabled && !_suspended);
    _microphone = enabled;
    _desiredMicrophone = enabled;
  });
  daily.MediaTrackFacingMode _facing = daily.MediaTrackFacingMode.user;
  @override
  Future<void> flipCamera() => _control((client) async {
    final next = _facing.flipped;
    await client.setCameraFacingMode(facingMode: next);
    _facing = next;
  });
  @override
  Future<void> suspendMedia() async {
    _suspended = true;
    final client = _client;
    try {
      if (client != null) {
        await _device(
          client,
          () => client.setInputsEnabled(camera: false, microphone: false),
        );
      }
    } catch (_) {
      /* Device may already be disconnected. */
    }
  }

  @override
  Future<void> resumeMedia() async {
    if (!_suspended || _closed) return;
    _suspended = false;
    final client = _client;
    if (_phase != CallPhase.connected || client == null) return;
    try {
      await _device(
        client,
        () => client.setInputsEnabled(
          camera: _desiredCamera,
          microphone: _desiredMicrophone,
        ),
      );
    } catch (_) {
      _error = '카메라·마이크를 다시 켜지 못했어요. 권한을 확인해주세요.';
      _changed();
    }
  }

  Future<void> _device(
    daily.CallClient client,
    Future<void> Function() action,
  ) {
    final next = _deviceQueue.then((_) async {
      if (_closed || !identical(client, _client)) return;
      await action();
    });
    _deviceQueue = next.catchError((Object _) {});
    return next;
  }

  Future<void> _release() async {
    final client = _client;
    _client = null;
    final events = _events;
    _events = null;
    await events?.cancel();
    await _deviceQueue;
    await _renderQueue;
    _local = null;
    _remote = null;
    try {
      await _remoteView.setTrack(null);
      await _localView.setTrack(null);
    } catch (_) {}
    if (client != null) {
      // Daily 0.41 dispose leaves the call itself. Explicit leave followed by
      // dispose races the SDK's asynchronous participant refresh after "left".
      try {
        await client.dispose();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() => _closing ??= _close();
  Future<void> _close() async {
    _closed = true;
    _generation++;
    await _connectTask;
    await _release();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(
      close().whenComplete(() {
        _remoteView.dispose();
        _localView.dispose();
      }),
    );
    super.dispose();
  }
}
