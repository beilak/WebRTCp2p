import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/signaling_message.dart';

enum CallStage {
  idle,
  preparing,
  offerReady,
  answerReady,
  connecting,
  connected,
  ended,
}

class WebRtcCallController extends ChangeNotifier {
  WebRtcCallController();

  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  bool _renderersReady = false;

  CallStage stage = CallStage.idle;
  String status = 'Ready to start a private peer-to-peer demo call.';
  String? error;
  SignalingMessage? outgoingSignal;

  bool get hasOutgoingSignal => outgoingSignal != null;
  bool get isBusy => stage == CallStage.preparing || stage == CallStage.connecting;

  Future<void> initialize() async {
    if (_renderersReady) {
      return;
    }

    await localRenderer.initialize();
    await remoteRenderer.initialize();
    _renderersReady = true;
  }

  Future<void> createOffer() async {
    await _runGuarded(() async {
      await _resetPeerOnly();
      stage = CallStage.preparing;
      status = 'Opening camera and creating an offer...';
      notifyListeners();

      final peerConnection = await _createPeerConnection();
      final offer = await peerConnection.createOffer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await peerConnection.setLocalDescription(offer);
      final completedOffer = await _waitForCompleteLocalDescription();

      outgoingSignal = SignalingMessage(
        kind: SignalKind.offer,
        description: completedOffer,
        createdAt: DateTime.now().toUtc(),
      );
      stage = CallStage.offerReady;
      status = 'Offer is ready. Share it with the other device.';
      notifyListeners();
    });
  }

  Future<void> acceptOffer(SignalingMessage offer) async {
    if (offer.kind != SignalKind.offer) {
      throw const FormatException('Expected an offer signal.');
    }

    await _runGuarded(() async {
      await _resetPeerOnly();
      stage = CallStage.preparing;
      status = 'Opening camera and creating an answer...';
      notifyListeners();

      final peerConnection = await _createPeerConnection();
      await peerConnection.setRemoteDescription(offer.description);
      final answer = await peerConnection.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await peerConnection.setLocalDescription(answer);
      final completedAnswer = await _waitForCompleteLocalDescription();

      outgoingSignal = SignalingMessage(
        kind: SignalKind.answer,
        description: completedAnswer,
        createdAt: DateTime.now().toUtc(),
      );
      stage = CallStage.answerReady;
      status = 'Answer is ready. Send it back to the caller.';
      notifyListeners();
    });
  }

  Future<void> acceptAnswer(SignalingMessage answer) async {
    if (answer.kind != SignalKind.answer) {
      throw const FormatException('Expected an answer signal.');
    }
    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      throw StateError('Create an offer before applying an answer.');
    }

    await _runGuarded(() async {
      stage = CallStage.connecting;
      status = 'Applying answer and connecting...';
      notifyListeners();

      await peerConnection.setRemoteDescription(answer.description);
      stage = CallStage.connected;
      status = 'Connected. Media is flowing directly between peers when possible.';
      notifyListeners();
    });
  }

  Future<void> hangUp() async {
    await _runGuarded(() async {
      await _resetPeerOnly();
      stage = CallStage.ended;
      status = 'Call ended. Start again whenever you are ready.';
      notifyListeners();
    });
  }

  Future<void> disposeAll() async {
    await _resetPeerOnly();
    if (_renderersReady) {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    }
  }

  Future<void> _runGuarded(Future<void> Function() body) async {
    try {
      error = null;
      await body();
    } catch (exception) {
      error = exception.toString();
      status = 'Something went wrong. Check permissions and signaling text.';
      notifyListeners();
      rethrow;
    }
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    await initialize();

    final peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });
    _peerConnection = peerConnection;

    peerConnection.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        stage = CallStage.connected;
        status = 'Connected. Remote video is available.';
        notifyListeners();
      }
    };

    peerConnection.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        stage = CallStage.connected;
        status = 'Connected. Media is flowing directly between peers when possible.';
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        status = 'Connection failed. Try regenerating the QR codes.';
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        status = 'Peer disconnected.';
      }
      notifyListeners();
    };

    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {
        'facingMode': 'user',
        'width': {'ideal': 1280},
        'height': {'ideal': 720},
      },
    });
    _localStream = stream;
    localRenderer.srcObject = stream;

    for (final track in stream.getTracks()) {
      await peerConnection.addTrack(track, stream);
    }

    return peerConnection;
  }

  Future<RTCSessionDescription> _waitForCompleteLocalDescription() async {
    final peerConnection = _peerConnection;
    if (peerConnection == null) {
      throw StateError('Peer connection is not initialized.');
    }

    final completer = Completer<void>();
    Timer? timeout;

    peerConnection.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
          !completer.isCompleted) {
        completer.complete();
      }
    };

    timeout = Timer(const Duration(seconds: 4), () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    if (peerConnection.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    await completer.future;
    timeout.cancel();

    final description = await peerConnection.getLocalDescription();
    if (description == null) {
      throw StateError('Local description was not created.');
    }
    return description;
  }

  Future<void> _resetPeerOnly() async {
    outgoingSignal = null;
    remoteRenderer.srcObject = null;

    final peerConnection = _peerConnection;
    _peerConnection = null;
    if (peerConnection != null) {
      await peerConnection.close();
      await peerConnection.dispose();
    }

    final stream = _localStream;
    _localStream = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }
    localRenderer.srcObject = null;
  }
}
