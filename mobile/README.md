# Szybka Fucha Mobile App

Flutter mobile application for Szybka Fucha platform.

## Quick Start

### Run on Physical iPhone

The easiest way to run the app on your physical iPhone:

```bash
# From project root
./run_ios.sh

# Or from mobile directory
cd mobile
./scripts/run_ios.sh
```

**First-time setup:**
1. Connect iPhone to Mac via USB
2. Trust Mac on iPhone (tap "Trust This Computer")
3. Enable Developer Mode: Settings → Privacy & Security → Developer Mode → ON
4. Configure code signing in Xcode (see below)

**Configure code signing:**
```bash
open mobile/ios/Runner.xcworkspace
```
In Xcode: Runner → Signing & Capabilities → Select your Team

### Run on Android Emulator

The easiest way to run the app on Android emulator:

```bash
# From project root
./run_android.sh

# Or from mobile directory
cd mobile
./scripts/run_android.sh
```

This script will:
- Check if Android emulator is running
- Launch the emulator if needed (Pixel 7 API 34)
- Wait for emulator to be ready
- Install dependencies if needed
- Launch the Flutter app

### Manual Run

**iOS:**
```bash
cd mobile
flutter run -d ios  # or specific device ID
```

**Android:**
```bash
# 1. Launch emulator
flutter emulators --launch Pixel_7_API_34

# 2. Wait for emulator to boot, then run
flutter run -d emulator-5554
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
