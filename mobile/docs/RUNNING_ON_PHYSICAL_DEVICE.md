# Running Flutter App on Physical Device (Mac)

Guide for testing the Szybka Fucha mobile app on a physical iPhone or Android device connected to your Mac.

---

## 📋 Prerequisites

### For iOS (iPhone/iPad):
- Mac with Xcode installed
- Apple Developer account (free account works for development)
- iPhone/iPad connected via USB cable
- Device unlocked and trusted

### For Android:
- Android Studio installed (or Android SDK)
- USB Debugging enabled on Android device
- Device connected via USB cable
- Developer options enabled on device

---

## 🔍 Step 1: Check Connected Devices

First, verify that your device is detected by Flutter:

**Option A: Using helper script (Recommended)**
```bash
cd mobile
./scripts/check_device.sh
```

This script will:
- Check Flutter installation
- Run `flutter doctor`
- List connected devices
- Show Mac IP address for backend connection

**Option B: Manual check**
```bash
cd mobile
flutter devices
```

**Expected output:**
```
2 connected devices:

iPhone 15 Pro (mobile) • 00008030-001A... • ios • com.apple.CoreSimulator.Simulator.iOS-17-0 (simulator)
iPhone 14 (mobile)    • abc123def456...  • ios • iOS 17.1.2 (physical)
```

Or for Android:
```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 14 (API 34) (emulator)
SM-G998B (mobile)           • R58M90ABCDE   • android-arm64 • Android 13 (API 33) (physical)
```

---

## 📱 Running on iOS Device

### Step 1: Enable Developer Mode on iPhone

1. **Settings** → **Privacy & Security** → **Developer Mode**
2. Toggle **Developer Mode** ON
3. Restart iPhone when prompted

### Step 2: Trust Your Mac

1. Connect iPhone to Mac via USB
2. On iPhone, tap **"Trust This Computer"** when prompted
3. Enter your iPhone passcode

### Step 3: Check Code Signing

Open Xcode to configure signing:

```bash
open mobile/ios/Runner.xcworkspace
```

In Xcode:
1. Select **Runner** project in left sidebar
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** (Apple ID)
5. Xcode will automatically create a provisioning profile

### Step 4: Run on Device

**Option A: Using Flutter CLI (Recommended)**

```bash
cd mobile

# List available devices
flutter devices

# Run on specific iOS device
flutter run -d <device-id>

# Or run on first iOS device found
flutter run -d ios
```

**Option B: Using Xcode**

1. Open `mobile/ios/Runner.xcworkspace` in Xcode
2. Select your device from the device dropdown (top toolbar)
3. Click **Run** button (▶️) or press `Cmd + R`

**Option C: Quick Run (Auto-detect)**

```bash
cd mobile
flutter run
```

Flutter will automatically select the connected device if only one is available.

---

## 🤖 Running on Android Device

### Step 1: Enable Developer Options

1. **Settings** → **About Phone**
2. Tap **Build Number** 7 times
3. You'll see "You are now a developer!"

### Step 2: Enable USB Debugging

1. **Settings** → **Developer Options**
2. Toggle **USB Debugging** ON
3. When connecting to Mac, tap **"Allow USB Debugging"** on device
4. Check **"Always allow from this computer"** (optional)

### Step 3: Verify ADB Connection

```bash
# Check if device is detected by ADB
adb devices
```

**Expected output:**
```
List of devices attached
R58M90ABCDE    device
```

If device shows as "unauthorized":
- Unplug and replug USB cable
- Tap "Allow USB Debugging" on device

### Step 4: Run on Device

```bash
cd mobile

# List available devices
flutter devices

# Run on specific Android device
flutter run -d <device-id>

# Or run on first Android device found
flutter run -d android
```

**Quick Run:**
```bash
cd mobile
flutter run
```

---

## 🚀 Common Flutter Commands

### Run Commands

```bash
# Run on connected device (auto-detect)
flutter run

# Run on specific device
flutter run -d <device-id>

# Run in release mode (faster, no hot reload)
flutter run --release

# Run with specific flavor/profile
flutter run --flavor dev
```

### Build Commands

```bash
# Build iOS app
flutter build ios

# Build Android APK
flutter build apk

# Build Android App Bundle (for Play Store)
flutter build appbundle

# Build for specific device
flutter build ios --release
flutter build apk --release
```

### Device Management

```bash
# List all connected devices
flutter devices

# List only physical devices
flutter devices | grep -v simulator | grep -v emulator

# Get device info
flutter doctor -v
```

### Hot Reload & Hot Restart

While app is running:
- Press `r` in terminal → **Hot Reload** (fast, keeps state)
- Press `R` in terminal → **Hot Restart** (full restart)
- Press `q` in terminal → **Quit** app

---

## 🔧 Configuration

### iOS Configuration

**Update Bundle Identifier (if needed):**

Edit `mobile/ios/Runner.xcodeproj/project.pbxproj` or use Xcode:
- **Runner** → **Signing & Capabilities**
- Change **Bundle Identifier** (e.g., `com.szymon.szybkafucha`)

**Update App Name:**

Edit `mobile/ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Szybka Fucha</string>
```

### Android Configuration

**Update Package Name (if needed):**

Edit `mobile/android/app/build.gradle.kts`:
```kotlin
android {
    namespace = "com.szymon.szybkafucha"
    // ...
}
```

**Update App Name:**

Edit `mobile/android/app/src/main/AndroidManifest.xml`:
```xml
<application
    android:label="Szybka Fucha"
    ...>
```

---

## 🌐 Backend Connection

### Development Backend URL

Make sure your backend is running and accessible from your device:

**For iOS Simulator/Emulator:**
- Use `localhost` or `127.0.0.1`
- Backend URL: `http://localhost:3000`

**For Physical Device:**
- Use your Mac's local IP address
- Find Mac IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
- Backend URL: `http://192.168.1.XXX:3000` (replace with your IP)

**Update API Base URL:**

Check `mobile/lib/core/config/api_config.dart` or similar:
```dart
const String baseUrl = 'http://192.168.1.XXX:3000/api/v1';
```

**Important:** Make sure your Mac's firewall allows connections on port 3000, or temporarily disable firewall for testing.

---

## 🐛 Troubleshooting

### iOS Issues

**Problem: "No devices found"**
```bash
# Solution 1: Restart Xcode
killall Xcode
open mobile/ios/Runner.xcworkspace

# Solution 2: Clean and rebuild
cd mobile
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

**Problem: "Code signing error"**
- Open Xcode: `open mobile/ios/Runner.xcworkspace`
- Select your Team in Signing & Capabilities
- Xcode will auto-generate provisioning profile

**Problem: "Device not trusted"**
- Unlock iPhone
- Settings → General → VPN & Device Management
- Trust your developer certificate

**Problem: "Could not launch app"**
```bash
# Clean build
cd mobile
flutter clean
flutter pub get
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter run
```

### Android Issues

**Problem: "No devices found"**
```bash
# Check ADB
adb devices

# Restart ADB server
adb kill-server
adb start-server
adb devices

# Check USB connection
# Try different USB cable or USB port
```

**Problem: "Device unauthorized"**
- Unplug and replug USB cable
- On device: Tap "Allow USB Debugging"
- Check "Always allow from this computer"

**Problem: "Gradle build failed"**
```bash
cd mobile
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

**Problem: "INSTALL_FAILED_INSUFFICIENT_STORAGE"**
- Free up space on Android device
- Or uninstall previous version of app

### General Issues

**Problem: "Hot reload not working"**
- Use Hot Restart instead: Press `R` in terminal
- Or stop and restart: Press `q`, then `flutter run`

**Problem: "Backend connection failed"**
- Check if backend is running: `curl http://localhost:3000/health`
- For physical device, use Mac's IP address (not localhost)
- Check firewall settings on Mac
- Ensure device and Mac are on same WiFi network

**Problem: "App crashes on launch"**
```bash
# Check logs
flutter logs

# Run with verbose logging
flutter run -v

# Check for missing dependencies
flutter pub get
```

---

## 📊 Useful Commands Reference

### Quick Reference Card

```bash
# Navigate to mobile directory
cd mobile

# Check devices
flutter devices

# Run on device
flutter run

# Run in release mode
flutter run --release

# Hot reload (while running)
# Press 'r' in terminal

# Hot restart (while running)
# Press 'R' in terminal

# Stop app (while running)
# Press 'q' in terminal

# Clean build
flutter clean
flutter pub get

# Check Flutter setup
flutter doctor -v

# View logs
flutter logs
```

---

## 🔐 Development vs Production

### Development Mode (Default)
```bash
flutter run
```
- Hot reload enabled
- Debug symbols included
- Slower performance
- Verbose logging

### Release Mode
```bash
flutter run --release
```
- No hot reload
- Optimized performance
- Smaller app size
- Production-like behavior

---

## 📝 Step-by-Step Checklist

### First Time Setup

**iOS:**
- [ ] Install Xcode from App Store
- [ ] Open Xcode and accept license
- [ ] Connect iPhone via USB
- [ ] Trust Mac on iPhone
- [ ] Enable Developer Mode on iPhone
- [ ] Open `mobile/ios/Runner.xcworkspace` in Xcode
- [ ] Select Team in Signing & Capabilities
- [ ] Run `flutter devices` to verify

**Android:**
- [ ] Install Android Studio
- [ ] Enable Developer Options on Android device
- [ ] Enable USB Debugging
- [ ] Connect device via USB
- [ ] Allow USB Debugging on device
- [ ] Run `adb devices` to verify
- [ ] Run `flutter devices` to verify

### Running App

- [ ] Navigate to `mobile` directory
- [ ] Ensure backend is running (if needed)
- [ ] Run `flutter devices` to see connected device
- [ ] Run `flutter run` or `flutter run -d <device-id>`
- [ ] Wait for app to build and install
- [ ] App should launch automatically on device

---

## 🎯 Tips & Best Practices

1. **Keep USB cable connected** during development for faster builds
2. **Use release mode** occasionally to test real performance
3. **Check device logs** if app crashes: `flutter logs`
4. **Clean build** if you encounter strange errors: `flutter clean`
5. **Keep Flutter updated**: `flutter upgrade`
6. **For backend testing**, use Mac's IP address, not localhost
7. **Enable "Stay Awake"** on device to prevent screen lock during testing

---

## 🛠️ Helper Script

A helper script is available to quickly check your setup:

```bash
cd mobile
./scripts/check_device.sh
```

This script will:
- ✅ Check Flutter installation
- ✅ Run `flutter doctor` to verify setup
- ✅ List all connected devices
- ✅ Show Mac IP address for backend connection
- ✅ Provide ready-to-use commands

---

## 📚 Additional Resources

- [Flutter Device Setup](https://docs.flutter.dev/get-started/install/macos)
- [iOS Development Setup](https://docs.flutter.dev/deployment/ios)
- [Android Development Setup](https://docs.flutter.dev/deployment/android)
- [Flutter Run Commands](https://docs.flutter.dev/tools/flutter-run)

---

## 🆘 Getting Help

If you encounter issues:

1. **Check Flutter Doctor:**
   ```bash
   flutter doctor -v
   ```
   Fix any issues shown in red

2. **Check Device Connection:**
   ```bash
   flutter devices
   ```

3. **Check Logs:**
   ```bash
   flutter logs
   ```

4. **Clean and Rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

*Last updated: 2026-01-22*
*For Szybka Fucha Mobile App*
