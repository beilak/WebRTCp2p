import 'dart:convert';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/signaling_message.dart';

class SignalingCodec {
  const SignalingCodec();

  static const prefix = 'w2:';
  static const legacyPrefix = 'webrtc-p2p-demo:';
  static const urlSignalKey = 's';
  static const legacyUrlSignalKey = 'signal';

  String encode(SignalingMessage message) {
    final kindCode = switch (message.kind) {
      SignalKind.offer => 'o',
      SignalKind.answer => 'a',
    };
    final sdp = message.description.sdp;

    if (sdp == null || sdp.isEmpty) {
      throw const FormatException('Signal description is missing SDP.');
    }

    return '$prefix$kindCode:${_encodeBase64Url(utf8.encode(sdp))}';
  }

  SignalingMessage decode(String value) {
    final trimmed = value.trim();
    final payload = extractSignalText(trimmed) ?? trimmed;

    if (payload.startsWith(prefix)) {
      return _decodeCompact(payload);
    }

    return _decodeLegacy(payload);
  }

  String buildSignalUrl({
    required Uri baseUri,
    required String signalText,
  }) {
    return baseUri.replace(fragment: '$urlSignalKey=$signalText').toString();
  }

  String? extractSignalText(String value) {
    final trimmed = value.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) {
      return null;
    }

    final querySignal = _extractSignalParameter(parsed.queryParameters);
    if (querySignal != null) {
      return querySignal;
    }

    final fragment = parsed.fragment;
    if (fragment.isEmpty) {
      return null;
    }

    final fragmentParameters = Uri.splitQueryString(fragment);
    return _extractSignalParameter(fragmentParameters);
  }

  SignalingMessage _decodeCompact(String value) {
    final compactPayload = value.substring(prefix.length);
    final separatorIndex = compactPayload.indexOf(':');
    if (separatorIndex <= 0 || separatorIndex == compactPayload.length - 1) {
      throw const FormatException('Compact signal payload is malformed.');
    }

    final kindCode = compactPayload.substring(0, separatorIndex);
    final encodedSdp = compactPayload.substring(separatorIndex + 1);
    final kind = switch (kindCode) {
      'o' => SignalKind.offer,
      'a' => SignalKind.answer,
      _ => throw const FormatException('Compact signal kind is unknown.'),
    };
    final sdp = utf8.decode(base64Url.decode(_normalizeBase64(encodedSdp)));

    return SignalingMessage(
      kind: kind,
      description: RTCSessionDescription(sdp, kind.name),
      createdAt: DateTime.now().toUtc(),
    );
  }

  SignalingMessage _decodeLegacy(String value) {
    final signal = value.startsWith(legacyPrefix)
        ? value.substring(legacyPrefix.length)
        : value;
    final decoded = utf8.decode(base64Url.decode(_normalizeBase64(signal)));
    final json = jsonDecode(decoded);

    if (json is! Map<String, Object?>) {
      throw const FormatException('Signal payload is not an object.');
    }

    return SignalingMessage.fromJson(json);
  }

  String? _extractSignalParameter(Map<String, String> parameters) {
    final signal = parameters[urlSignalKey];
    if (signal != null && signal.isNotEmpty) {
      return signal;
    }

    final legacySignal = parameters[legacyUrlSignalKey];
    if (legacySignal != null && legacySignal.isNotEmpty) {
      return legacySignal;
    }

    return null;
  }

  String _encodeBase64Url(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  String _normalizeBase64(String value) {
    final padding = value.length % 4;
    if (padding == 0) {
      return value;
    }
    return value.padRight(value.length + 4 - padding, '=');
  }
}
