import 'package:flutter/material.dart';

import '../models/signaling_message.dart';
import '../services/signaling_codec.dart';
import '../services/webrtc_call_controller.dart';
import '../widgets/signal_card.dart';
import '../widgets/video_tile.dart';
import 'scan_signal_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _call = WebRtcCallController();
  final _codec = const SignalingCodec();
  final _signalTextController = TextEditingController();
  bool _checkedLaunchUrl = false;

  @override
  void initState() {
    super.initState();
    _call.addListener(_onCallChanged);
    _call.initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyLaunchUrlSignal());
  }

  @override
  void dispose() {
    _call.removeListener(_onCallChanged);
    _signalTextController.dispose();
    _call.disposeAll();
    super.dispose();
  }

  void _onCallChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final outgoingSignal = _call.outgoingSignal;
    final payload = outgoingSignal == null ? null : _codec.encode(outgoingSignal);
    final signalUrl = payload == null
        ? null
        : _codec.buildSignalUrl(baseUri: Uri.base, signalText: payload);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC P2P Demo'),
        actions: [
          IconButton(
            tooltip: 'Hang up',
            onPressed: _call.stage == CallStage.idle || _call.isBusy
                ? null
                : () => _handleAction(_call.hangUp),
            icon: const Icon(Icons.call_end_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            _HeroHeader(status: _call.status, error: _call.error),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 780;
                final tiles = [
                  VideoTile(
                    title: 'You',
                    renderer: _call.localRenderer,
                    placeholderIcon: Icons.videocam_rounded,
                    mirror: true,
                  ),
                  VideoTile(
                    title: 'Peer',
                    renderer: _call.remoteRenderer,
                    placeholderIcon: Icons.person_rounded,
                  ),
                ];

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 16),
                      Expanded(child: tiles[1]),
                    ],
                  );
                }

                return Column(
                  children: [
                    tiles[0],
                    const SizedBox(height: 16),
                    tiles[1],
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            _QuickStartCard(
              isBusy: _call.isBusy,
              onCreateOffer: () => _handleAction(_call.createOffer),
              onScan: _scanSignal,
            ),
            const SizedBox(height: 18),
            const _ConnectionOptionsCard(),
            const SizedBox(height: 18),
            _ManualSignalCard(
              controller: _signalTextController,
              isBusy: _call.isBusy,
              onApply: () => _applySignal(_signalTextController.text),
            ),
            if (payload != null) ...[
              const SizedBox(height: 18),
              SignalCard(
                title: outgoingSignal!.kind == SignalKind.offer
                    ? 'Offer QR'
                    : 'Answer QR',
                payload: payload,
                signalUrl: signalUrl!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _applyLaunchUrlSignal() async {
    if (_checkedLaunchUrl || !mounted) {
      return;
    }
    _checkedLaunchUrl = true;

    final signalText = _codec.extractSignalText(Uri.base.toString());
    if (signalText == null || signalText.isEmpty) {
      return;
    }

    _signalTextController.text = signalText;
    _showSnackBar('Signal loaded from URL. Applying it now...');
    await _applySignal(signalText);
  }

  Future<void> _scanSignal() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanSignalPage()),
    );
    if (result == null || result.isEmpty) {
      return;
    }
    _signalTextController.text = result;
    await _applySignal(result);
  }

  Future<void> _applySignal(String rawSignal) async {
    if (rawSignal.trim().isEmpty) {
      _showSnackBar('Paste, scan, or open a signal URL first.');
      return;
    }

    await _handleAction(() async {
      final signal = _codec.decode(rawSignal);
      switch (signal.kind) {
        case SignalKind.offer:
          await _call.acceptOffer(signal);
          break;
        case SignalKind.answer:
          await _call.acceptAnswer(signal);
          break;
      }
    });
  }

  Future<void> _handleAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (exception) {
      _showSnackBar(exception.toString());
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.status, required this.error});

  final String status;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Text(
                  'No backend • QR, URL, or compact signals • STUN only',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Demo video calls with QR, URL, or compact signals.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF151A2D),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              status,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({
    required this.isBusy,
    required this.onCreateOffer,
    required this.onScan,
  });

  final bool isBusy;
  final VoidCallback onCreateOffer;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick start', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const Text(
              'Device A creates an offer. Device B scans, opens the URL, or pastes the compact signal and creates an answer. Device A applies the answer to connect.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: isBusy ? null : onCreateOffer,
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: const Text('Create offer'),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onScan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan signal'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionOptionsCard extends StatelessWidget {
  const _ConnectionOptionsCard();

  @override
  Widget build(BuildContext context) {
    final options = [
      _ConnectionOption(
        icon: Icons.qr_code_scanner_rounded,
        title: 'QR scan',
        description: 'Fastest when both iPhones are side by side.',
      ),
      _ConnectionOption(
        icon: Icons.short_text_rounded,
        title: 'Compact signal',
        description: 'Copy/paste the compact signal if the QR is too dense.',
      ),
      _ConnectionOption(
        icon: Icons.link_rounded,
        title: 'Signal URL',
        description:
            'Share a link with the compact signal in the URL fragment.',
      ),
      _ConnectionOption(
        icon: Icons.ios_share_rounded,
        title: 'iOS share sheet',
        description: 'Send either value through AirDrop, Messages, or Notes.',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection exchange options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'This demo has no signaling server, so peers exchange offer/answer data directly using any of these options.',
            ),
            const SizedBox(height: 16),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      child: Icon(option.icon),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.description,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionOption {
  const _ConnectionOption({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

class _ManualSignalCard extends StatelessWidget {
  const _ManualSignalCard({
    required this.controller,
    required this.isBusy,
    required this.onApply,
  });

  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Manual fallback',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Paste an offer/answer signal or a signal URL here...',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onApply,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Apply signal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
