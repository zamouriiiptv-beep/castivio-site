# Prime Player

Ultra-fast IPTV player for Android, iOS, Android TV, and Fire TV Stick.

## Setup

```bash
# 1. Install Flutter
# https://docs.flutter.dev/get-started/install

# 2. Get dependencies
flutter pub get

# 3. Run on Android
flutter run --release

# 4. Build APK
flutter build apk --release --split-per-abi

# 5. Build Android TV / Fire TV APK
flutter build apk --release --target-platform android-arm64
```

## Performance Notes

- Uses **media_kit** (libmpv) with hardware decoding — fastest open-source IPTV engine
- M3U parsed in a background Isolate — UI stays at 60fps even with 30,000 channels
- Virtual scroll (ListView.builder) — 30,000 channels load instantly
- Pre-connect on pointer-down — channel opens before your finger lifts
- DNS pre-resolution via MPV `prefetch-playlist`
- 16MB stream buffer with 2s readahead — no buffering interruptions
