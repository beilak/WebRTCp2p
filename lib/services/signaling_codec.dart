import 'dart:convert';

import '../models/signaling_message.dart';

class SignalingCodec {
  const SignalingCodec();

  static const prefix = 'webrtc-p2p-demo:';

  String encode(SignalingMessage message) {
    final jsonPayload = jsonEncode(message.toJson());
    final encoded = base64Url.encode(utf8.encode(jsonPayload));
    return '$prefix$encoded';
  }

  SignalingMessage decode(String value) {
    final trimmed = value.trim();
    final payload = trimmed.startsWith(prefix)
        ? trimmed.substring(prefix.length)
        : trimmed;
    final decoded = utf8.decode(base64Url.decode(_normalizeBase64(payload)));
    final json = jsonDecode(decoded);

    if (json is! Map<String, Object?>) {
      throw const FormatException('Signal payload is not an object.');
    }

    return SignalingMessage.fromJson(json);
  }

  String _normalizeBase64(String value) {
    final padding = value.length % 4;
    if (padding == 0) {
      return value;
    }
    return value.padRight(value.length + 4 - padding, '=');
  }
}
