# Quick Start - Run on Physical Device

## 🚀 Quick Commands

```bash
# 1. Navigate to mobile directory
cd mobile

# 2. Check if device is connected
flutter devices

# 3. Run app on device
flutter run
```

That's it! Flutter will automatically detect and run on your connected device.

---

## 📱 Platform-Specific Quick Setup

### iOS (iPhone/iPad)

```bash
# 1. Connect iPhone via USB
# 2. Trust Mac on iPhone (tap "Trust")
# 3. Enable Developer Mode: Settings → Privacy & Security → Developer Mode

# 4. Open Xcode to configure signing
open ios/Runner.xcworkspace
# Select your Team in Signing & Capabilities

# 5. Run
cd mobile
flutter run
```

### Android

```bash
# 1. Enable Developer Options:
#    Settings → About Phone → Tap "Build Number" 7 times

# 2. Enable USB Debugging:
#    Settings → Developer Options → USB Debugging ON

# 3. Connect device via USB
# 4. Allow USB Debugging on device when prompted

# 5. Run
cd mobile
flutter run
```

---

## 🔧 Common Issues Quick Fix

**Device not found?**
```bash
flutter devices
# If empty, check USB connection and device settings
```

**iOS signing error?**
```bash
open ios/Runner.xcworkspace
# Fix signing in Xcode
```

**Android unauthorized?**
```bash
adb devices
# Unplug/replug USB, allow on device
```

**Backend connection failed?**
- Use Mac's IP address (not localhost)
- Find IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
- Update API config in app

---

## ⌨️ While App is Running

- Press `r` → Hot Reload
- Press `R` → Hot Restart  
- Press `q` → Quit

---

For detailed guide, see: `RUNNING_ON_PHYSICAL_DEVICE.md`
