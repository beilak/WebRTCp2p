# WebRTC P2P Demo

A clean Flutter demo app for one-to-one video calls without a backend signaling server. The app exchanges WebRTC offers and answers through QR codes, with copy/share text as a reliable fallback for dense SDP payloads.

## What is included

- Flutter Material 3 app with a light, modern responsive UI.
- Camera and microphone WebRTC call flow powered by `flutter_webrtc`.
- Backend-free signaling:
  1. Device A creates an offer QR.
  2. Device B scans the offer and creates an answer QR.
  3. Device A scans the answer to complete the peer connection.
- Manual copy/paste fallback for iOS Safari, desktop browsers, or dense QR codes.
- GitHub Actions CI/CD for analyze, tests, web release artifacts, GitHub Pages deployment, and unsigned iOS release builds.

## Try it on iPhone

### Option 1: Web app through GitHub Pages

1. Push this repository to GitHub with GitHub Pages enabled for Actions.
2. Open the deployed Pages URL from the `Deploy web to GitHub Pages` workflow job.
3. Allow camera and microphone access in Safari.
4. Open the same URL on a second device and follow the QR flow.

> Web camera access requires HTTPS or `localhost`. GitHub Pages satisfies HTTPS.

### Option 2: Local web run

```bash
flutter pub get
flutter run -d chrome
```

For iPhone testing on the same network, serve a release build over HTTPS or use a secure tunnel:

```bash
flutter build web --release
```

### Option 3: Unsigned iOS artifact from CI

The `Build unsigned iOS app` job creates `ios-release-unsigned`. It is useful for CI validation and for teams that add their own signing step. Installing on a physical iPhone still requires Apple code signing through Xcode, an Apple Developer account, or a device-management/TestFlight pipeline.

## Development

If platform folders are missing in a fresh checkout, generate them with Flutter:

```bash
flutter create --platforms=web,ios --org com.example .
```

Then run the usual checks:

```bash
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

## Notes and limitations

- There is no TURN server. Calls work best on friendly networks. Some carrier, corporate, or symmetric NAT networks can block peer-to-peer media.
- SDP payloads can be large after ICE candidate gathering. The QR is shown first for the demo flow, while copy/share is available as a fallback.
- No app backend stores or relays call metadata.
