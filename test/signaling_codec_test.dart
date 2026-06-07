import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_p2p_demo/models/signaling_message.dart';
import 'package:webrtc_p2p_demo/services/signaling_codec.dart';

void main() {
  test('round-trips offer payloads', () {
    const codec = SignalingCodec();
    final message = SignalingMessage(
      kind: SignalKind.offer,
      description: RTCSessionDescription('v=0\\r\\n', 'offer'),
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final encoded = codec.encode(message);
    final decoded = codec.decode(encoded);

    expect(encoded, startsWith(SignalingCodec.prefix));
    expect(decoded.kind, SignalKind.offer);
    expect(decoded.description.type, 'offer');
    expect(decoded.description.sdp, 'v=0\\r\\n');
    expect(decoded.createdAt, DateTime.utc(2026, 1, 1));
  });
}
