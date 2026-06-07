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

    final rawSdpBytes = utf8.encode(sdp);
    final rawPayload = _encodeBase64Url(rawSdpBytes);
    final compressedSdpBytes = _compressBytes(rawSdpBytes);

    if (compressedSdpBytes != null &&
        compressedSdpBytes.length < rawSdpBytes.length) {
      final compressedPayload = _encodeBase64Url(compressedSdpBytes);
      if (compressedPayload.length + 2 < rawPayload.length) {
        return '$prefix$kindCode:z:$compressedPayload';
      }
    }

    return '$prefix$kindCode:$rawPayload';
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
    final sdpBytes = encodedSdp.startsWith('z:')
        ? _decompressBytes(
            base64Url.decode(_normalizeBase64(encodedSdp.substring(2))),
          )
        : base64Url.decode(_normalizeBase64(encodedSdp));
    final sdp = utf8.decode(sdpBytes);

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

  List<int>? _compressBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      return const [];
    }

    final dictionary = <String, int>{
      for (var i = 0; i < 256; i++) String.fromCharCode(i): i,
    };
    var nextCode = 256;
    var current = String.fromCharCode(bytes.first);
    final codes = <int>[];

    for (final byte in bytes.skip(1)) {
      final character = String.fromCharCode(byte);
      final combined = current + character;

      if (dictionary.containsKey(combined)) {
        current = combined;
        continue;
      }

      codes.add(dictionary[current]!);
      if (nextCode > 0xffff) {
        return null;
      }
      dictionary[combined] = nextCode++;
      current = character;
    }

    codes.add(dictionary[current]!);

    return [
      for (final code in codes) ...[code >> 8, code & 0xff],
    ];
  }

  List<int> _decompressBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      return const [];
    }
    if (bytes.length.isOdd) {
      throw const FormatException('Compressed signal payload is malformed.');
    }

    final codes = <int>[
      for (var index = 0; index < bytes.length; index += 2)
        (bytes[index] << 8) | bytes[index + 1],
    ];
    final dictionary = <int, String>{
      for (var i = 0; i < 256; i++) i: String.fromCharCode(i),
    };
    var nextCode = 256;
    var previous = dictionary[codes.first];

    if (previous == null) {
      throw const FormatException('Compressed signal payload is malformed.');
    }

    final output = <int>[]..addAll(previous.codeUnits);

    for (final code in codes.skip(1)) {
      final inferredEntry = code == nextCode ? previous + previous[0] : null;
      final entry = dictionary[code] ?? inferredEntry;
      if (entry == null) {
        throw const FormatException('Compressed signal payload is malformed.');
      }

      output.addAll(entry.codeUnits);
      if (nextCode <= 0xffff) {
        dictionary[nextCode++] = previous + entry[0];
      }
      previous = entry;
    }

    return output;
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
