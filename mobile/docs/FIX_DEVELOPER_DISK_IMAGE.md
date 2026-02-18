# Fix "Developer Disk Image Could Not Be Mounted" Error

## Problem

You're getting this error:
```
The developer disk image could not be mounted on this device.
Error mounting image: 0xe800010f
kAMDMobileImageMounterPersonalizedBundleMissingVariantError
```

## Root Cause

Your iPhone is running **iOS 26.2.1**, but **Xcode 16.2** only supports up to **iOS 18.3**. This version mismatch prevents Xcode from mounting the developer disk image needed to run apps on your device.

## Solutions (Try in Order)

### Solution 1: Connect via USB (Not Wireless) ⭐ **Try This First**

The error often occurs with wireless connections. Use USB instead:

1. **Disconnect wireless connection** (if connected)
2. **Connect iPhone to Mac via USB cable**
3. **Unlock iPhone**
4. **Trust Mac** on iPhone (if prompted)
5. **Try running the app again:**
   ```bash
   cd mobile
   ./scripts/run_ios.sh
   ```

### Solution 2: Update Xcode

Your Xcode version may be too old for your iOS version:

1. **Open App Store**
2. **Search for "Xcode"**
3. **Click "Update"** if available
4. **Wait for update to complete** (this can take 30+ minutes)
5. **Restart Xcode**
6. **Try again**

Or download latest from: https://developer.apple.com/xcode/

### Solution 3: Download Additional Components

Xcode may need to download iOS support files:

1. **Open Xcode**
2. **Go to:** Xcode → Settings (or Preferences)
3. **Click "Platforms" tab**
4. **Check for available iOS platform downloads**
5. **Download if available**
6. **Wait for download to complete**
7. **Try again**

### Solution 4: Verify iOS Version

iOS 26.2.1 seems unusually high. Verify the actual version:

1. **On iPhone:** Settings → General → About
2. **Check "Version"** - is it really 26.2.1?
3. **If it's a beta version:**
   - Consider updating to stable iOS version
   - Or update Xcode to beta version that supports it

### Solution 5: Use iOS Simulator Instead

If you can't fix the device issue, use the iOS Simulator:

```bash
cd mobile
flutter run -d "iPhone 16 Pro"  # or any simulator
```

### Solution 6: Check Device in Xcode

1. **Open Xcode**
2. **Go to:** Window → Devices and Simulators (`Cmd + Shift + 2`)
3. **Select your iPhone** from left sidebar
4. **Check for any error messages**
5. **Look for "Use for Development" button** - click it if available
6. **Wait for device preparation** (may take a few minutes)

## Quick Fix Script

Run the diagnostic script:

```bash
cd mobile
./scripts/fix_developer_disk_image.sh
```

This will:
- Check Xcode version
- Check device connection
- Check available iOS runtimes
- Provide specific recommendations

## Manual Steps

### Step 1: Clean Xcode Derived Data

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData
```

### Step 2: Restart Services

```bash
# Kill Xcode and related processes
killall Xcode
killall com.apple.CoreSimulator.CoreSimulatorService

# Restart
open -a Xcode
```

### Step 3: Reconnect Device

1. **Unplug USB cable**
2. **Wait 5 seconds**
3. **Plug back in**
4. **Unlock iPhone**
5. **Trust Mac** (if prompted)

### Step 4: Try Building in Xcode

1. **Open project:**
   ```bash
   open mobile/ios/Runner.xcworkspace
   ```
2. **Select your iPhone** from device dropdown (top toolbar)
3. **Click Run** (▶️) or press `Cmd + R`
4. **Check error messages** in Xcode console

## Common Issues

### "Device not found"
- Connect via USB (not wireless)
- Unlock iPhone
- Trust Mac on iPhone
- Restart Xcode

### "Version mismatch"
- Update Xcode to latest version
- Or downgrade iOS on device (not recommended)

### "Wireless connection issues"
- Always use USB for first connection
- Wireless can be enabled after USB setup

## After Fixing

Once the error is resolved:

```bash
cd mobile
./scripts/run_ios.sh
```

Or manually:
```bash
flutter run -d ios
```

## Need More Help?

- Check Xcode console for detailed errors
- Run `flutter doctor -v` to check Flutter setup
- Check Apple Developer Forums for similar issues
- Consider using iOS Simulator for development
