import 'dart:convert';

import '../models/signaling_message.dart';

class SignalingCodec {
  const SignalingCodec();

  static const prefix = 'webrtc-p2p-demo:';
  static const urlSignalKey = 'signal';

  String encode(SignalingMessage message) {
    final jsonPayload = jsonEncode(message.toJson());
    final encoded = base64Url.encode(utf8.encode(jsonPayload));
    return '$prefix$encoded';
  }

  SignalingMessage decode(String value) {
    final trimmed = value.trim();
    final payload = extractSignalText(trimmed) ?? trimmed;
    final signal = payload.startsWith(prefix)
        ? payload.substring(prefix.length)
        : payload;
    final decoded = utf8.decode(base64Url.decode(_normalizeBase64(signal)));
    final json = jsonDecode(decoded);

    if (json is! Map<String, Object?>) {
      throw const FormatException('Signal payload is not an object.');
    }

    return SignalingMessage.fromJson(json);
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

    final querySignal = parsed.queryParameters[urlSignalKey];
    if (querySignal != null && querySignal.isNotEmpty) {
      return querySignal;
    }

    final fragment = parsed.fragment;
    if (fragment.isEmpty) {
      return null;
    }

    final fragmentParameters = Uri.splitQueryString(fragment);
    final fragmentSignal = fragmentParameters[urlSignalKey];
    if (fragmentSignal != null && fragmentSignal.isNotEmpty) {
      return fragmentSignal;
    }

    return null;
  }

  String _normalizeBase64(String value) {
    final padding = value.length % 4;
    if (padding == 0) {
      return value;
    }
    return value.padRight(value.length + 4 - padding, '=');
  }
}
