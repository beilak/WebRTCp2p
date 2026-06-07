import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_p2p_demo/models/signaling_message.dart';
import 'package:webrtc_p2p_demo/services/signaling_codec.dart';

void main() {
  test('round-trips offer payloads with compact text', () {
    const codec = SignalingCodec();
    final message = SignalingMessage(
      kind: SignalKind.offer,
      description: RTCSessionDescription('v=0\r\n', 'offer'),
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final encoded = codec.encode(message);
    final decoded = codec.decode(encoded);

    expect(encoded, startsWith(SignalingCodec.prefix));
    expect(encoded, isNot(contains('createdAt')));
    expect(decoded.kind, SignalKind.offer);
    expect(decoded.description.type, 'offer');
    expect(decoded.description.sdp, 'v=0\r\n');
  });

  test('compact payload is much shorter than the legacy JSON payload', () {
    const codec = SignalingCodec();
    final sdp = List.filled(
      40,
      'a=candidate:0 1 udp 2122252543 192.0.2.1 54400 typ host',
    ).join('\r\n');
    final message = SignalingMessage(
      kind: SignalKind.answer,
      description: RTCSessionDescription(sdp, 'answer'),
      createdAt: DateTime.utc(2026, 1, 2),
    );

    final compact = codec.encode(message);
    final decoded = codec.decode(compact);
    final legacyJson = jsonEncode(message.toJson());
    final legacy = '${SignalingCodec.legacyPrefix}'
        '${base64Url.encode(utf8.encode(legacyJson))}';

    expect(compact.length, lessThan(legacy.length * 0.75));
    expect(decoded.kind, SignalKind.answer);
    expect(decoded.description.type, 'answer');
    expect(decoded.description.sdp, sdp);
  });

  test('decodes compact signals from shareable URLs', () {
    const codec = SignalingCodec();
    final message = SignalingMessage(
      kind: SignalKind.answer,
      description: RTCSessionDescription('v=0\r\nanswer', 'answer'),
      createdAt: DateTime.utc(2026, 1, 2),
    );

    final signalText = codec.encode(message);
    final signalUrl = codec.buildSignalUrl(
      baseUri: Uri.parse('https://example.com/call/'),
      signalText: signalText,
    );
    final decoded = codec.decode(signalUrl);

    expect(signalUrl, contains('#s='));
    expect(decoded.kind, SignalKind.answer);
    expect(decoded.description.type, 'answer');
    expect(decoded.description.sdp, 'v=0\r\nanswer');
  });

  test('still decodes legacy signal URLs', () {
    const codec = SignalingCodec();
    final message = SignalingMessage(
      kind: SignalKind.offer,
      description: RTCSessionDescription('v=0\r\nlegacy', 'offer'),
      createdAt: DateTime.utc(2026, 1, 3),
    );
    final legacyJson = jsonEncode(message.toJson());
    final legacySignal = '${SignalingCodec.legacyPrefix}'
        '${base64Url.encode(utf8.encode(legacyJson))}';
    final legacyUrl = Uri.parse('https://example.com/call/')
        .replace(fragment: 'signal=$legacySignal')
        .toString();

    final decoded = codec.decode(legacyUrl);

    expect(decoded.kind, SignalKind.offer);
    expect(decoded.description.type, 'offer');
    expect(decoded.description.sdp, 'v=0\r\nlegacy');
    expect(decoded.createdAt, DateTime.utc(2026, 1, 3));
  });
}
