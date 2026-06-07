import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class VideoTile extends StatelessWidget {
  const VideoTile({
    required this.title,
    required this.renderer,
    required this.placeholderIcon,
    super.key,
    this.mirror = false,
  });

  final String title;
  final RTCVideoRenderer renderer;
  final IconData placeholderIcon;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final hasVideo = renderer.srcObject != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasVideo)
              RTCVideoView(
                renderer,
                mirror: mirror,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEAF0FF), Color(0xFFF9FBFF)],
                  ),
                ),
                child: Icon(
                  placeholderIcon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
              ),
            Positioned(
              left: 14,
              bottom: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
