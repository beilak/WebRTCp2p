# WebRTC P2P Demo

A clean Flutter demo app for one-to-one video calls without a backend signaling server. The app exchanges WebRTC offers and answers through QR codes, compact one-line text signals, shareable signal URLs, or the iOS share sheet.

## What is included

- Flutter Material 3 app with a light, modern responsive UI.
- Camera and microphone WebRTC call flow powered by `flutter_webrtc`.
- Backend-free compact signaling:
  1. Device A creates an offer.
  2. Device B receives the offer by QR scan, pasted compact signal, or signal URL and creates an answer.
  3. Device A receives the answer by QR scan, pasted compact signal, or signal URL to complete the peer connection.
- iOS-friendly alternatives when a QR code is too dense:
  - compact one-line signal copy/paste,
  - signal URL with the offer/answer in the URL fragment,
  - iOS share sheet through AirDrop, Messages, Notes, or another app.
- GitHub Actions CI/CD for analyze, tests, web release artifacts, GitHub Pages deployment, and unsigned iOS release builds.

## Try it on two iPhones

### Recommended: Web app through GitHub Pages

1. Push this repository to GitHub.
2. In repository settings, set **Pages** source to **GitHub Actions**.
3. Push to `main` and wait for the **Flutter CI/CD** workflow.
4. Open the deployed Pages URL from the `Deploy web to GitHub Pages` workflow job on both iPhones in Safari.
5. Allow camera and microphone access on both devices.

> Web camera access requires HTTPS or `localhost`. GitHub Pages satisfies HTTPS.

### Flow A: QR code

1. On iPhone A, tap **Create offer**.
2. On iPhone B, tap **Scan signal** and scan iPhone A's **Offer QR**.
3. On iPhone B, wait for the **Answer QR**.
4. On iPhone A, tap **Scan signal** and scan iPhone B's **Answer QR**.
5. The video call should connect.

### Flow B: compact one-line signal

Use this when the QR is too dense or the scanner cannot focus.

1. On iPhone A, tap **Create offer** and copy/share the **Compact signal**.
2. Send it to iPhone B with AirDrop, Messages, Notes, or any app.
3. On iPhone B, paste it into **Manual fallback** and tap **Apply signal**.
4. Copy/share iPhone B's answer **Compact signal** back to iPhone A.
5. On iPhone A, paste it into **Manual fallback** and tap **Apply signal**.

### Flow C: signal URL

Use this when you prefer sending a link instead of raw text.

1. On iPhone A, tap **Create offer** and copy/share the **Signal URL**.
2. Open that URL on iPhone B. The app reads the compact `#s=...` URL fragment and applies the offer.
3. On iPhone B, copy/share the answer **Signal URL**.
4. Open that answer URL on iPhone A to apply the answer and connect.

The signal stays in the URL fragment, so it is not sent to the static web host as an HTTP query string. Current links use the short `#s=...` fragment, and older `#signal=...` links are still accepted.

### Option: Local web run

```bash
flutter pub get
flutter run -d chrome
```

For iPhone testing on the same network, serve a release build over HTTPS or use a secure tunnel:

```bash
flutter build web --release
```

### Option: Unsigned iOS artifact from CI

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
- SDP payloads can be large after ICE candidate gathering. The app now emits a shorter compact signal format, but QR may still be dense on restrictive networks with many ICE candidates. Compact one-line signals and signal URLs are reliable fallbacks.
- No app backend stores or relays call metadata.
