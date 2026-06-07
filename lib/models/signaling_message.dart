import 'package:flutter_webrtc/flutter_webrtc.dart';

enum SignalKind { offer, answer }

class SignalingMessage {
  const SignalingMessage({
    required this.kind,
    required this.description,
    required this.createdAt,
  });

  final SignalKind kind;
  final RTCSessionDescription description;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'v': 1,
        'kind': kind.name,
        'sdp': description.sdp,
        'type': description.type,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory SignalingMessage.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String?;
    final sdp = json['sdp'] as String?;
    final type = json['type'] as String?;
    final createdAt = json['createdAt'] as String?;

    if (kindName == null || sdp == null || type == null) {
      throw const FormatException('Signal is missing required fields.');
    }

    return SignalingMessage(
      kind: SignalKind.values.byName(kindName),
      description: RTCSessionDescription(sdp, type),
      createdAt: createdAt == null
          ? DateTime.now().toUtc()
          : DateTime.parse(createdAt).toUtc(),
    );
  }
}
