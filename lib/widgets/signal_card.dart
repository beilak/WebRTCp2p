import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class SignalCard extends StatelessWidget {
  const SignalCard({
    required this.title,
    required this.payload,
    required this.signalUrl,
    super.key,
  });

  final String title;
  final String payload;
  final String signalUrl;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Scan the QR, copy the one-line signal, or share the signal URL.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 18),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E7F5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 236,
                    gapless: false,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: Color(0xFF151A2D),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: Color(0xFF151A2D),
                    ),
                  ),
                ),
              ),
            ),
            if (payload.length > 2400) ...[
              const SizedBox(height: 12),
              const Text(
                'This QR may be dense on small screens. The one-line signal or URL is the safest fallback.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9A6400)),
              ),
            ],
            const SizedBox(height: 16),
            _CopyableValue(
              label: 'One-line signal',
              value: payload,
              copiedMessage: 'Signal copied',
            ),
            const SizedBox(height: 12),
            _CopyableValue(
              label: 'Signal URL',
              value: signalUrl,
              copiedMessage: 'Signal URL copied',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => _share(
                    text: payload,
                    title: '$title one-line signal',
                  ),
                  icon: const Icon(Icons.short_text_rounded),
                  label: const Text('Share signal'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _share(
                    text: signalUrl,
                    title: '$title URL',
                  ),
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Share URL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _share({required String text, required String title}) {
    SharePlus.instance.share(
      ShareParams(text: text, subject: title, title: title),
    );
  }
}

class _CopyableValue extends StatelessWidget {
  const _CopyableValue({
    required this.label,
    required this.value,
    required this.copiedMessage,
  });

  final String label;
  final String value;
  final String copiedMessage;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E7F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF4E5A78),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              value,
              maxLines: 3,
              style: const TextStyle(
                color: Color(0xFF151A2D),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(copiedMessage)),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
