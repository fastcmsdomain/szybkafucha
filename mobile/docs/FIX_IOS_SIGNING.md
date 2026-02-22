# Fix iOS Code Signing Error

## Problem

You're getting this error:
```
Your team has no devices from which to generate a provisioning profile.
No profiles for 'pl.szybkafucha.mobile' were found
```

## Solution

### Method 1: Automatic Fix (Recommended)

Run the fix script:
```bash
cd mobile
./scripts/fix_ios_signing.sh
```

This will guide you through the process.

### Method 2: Manual Fix in Xcode

#### Step 1: Open Xcode Project

```bash
cd mobile
open ios/Runner.xcworkspace
```

**Important:** Always open `.xcworkspace`, not `.xcodeproj`

#### Step 2: Register Your Device

1. In Xcode, go to: **Window** → **Devices and Simulators** (or press `Cmd + Shift + 2`)
2. Connect your iPhone via USB
3. Select your iPhone from the left sidebar
4. Xcode will automatically register your device with your Apple Developer account

#### Step 3: Configure Signing

1. In Xcode, select **Runner** project in the left sidebar
2. Select **Runner** target (under TARGETS)
3. Go to **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** from the dropdown (your Apple ID)
6. Xcode will automatically:
   - Register your device (if not already done)
   - Create an App ID
   - Generate a provisioning profile
   - Download and install certificates

#### Step 4: Verify

You should see:
- ✅ "Signing certificate is valid"
- ✅ "Provisioning profile is valid"
- ✅ Your device listed under "Registered Devices"

### Method 3: Register Device via Apple Developer Portal

If automatic signing doesn't work:

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to: **Certificates, Identifiers & Profiles** → **Devices**
3. Click **+** to add a new device
4. Get your device UDID:
   ```bash
   # In Xcode: Window → Devices and Simulators → Select your iPhone → Copy UDID
   # Or via command line:
   xcrun xctrace list devices | grep "iPhone"
   ```
5. Enter device name and UDID
6. Click **Continue** → **Register**
7. Go back to Xcode and try again

## Troubleshooting

### "No devices found"

**Solution:**
- Connect iPhone via USB (not just wireless)
- Unlock iPhone
- Trust Mac on iPhone
- Restart Xcode

### "Team has no devices"

**Solution:**
- Make sure device is connected via USB
- Open Xcode → Window → Devices and Simulators
- Select your device - Xcode will register it automatically
- Wait a few seconds for registration to complete

### "Provisioning profile not found"

**Solution:**
1. In Xcode: Runner → Signing & Capabilities
2. Uncheck "Automatically manage signing"
3. Check it again
4. Select your Team
5. Xcode will regenerate the profile

### "Code signing error"

**Solution:**
```bash
cd mobile
flutter clean
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter pub get
```

Then try again in Xcode.

### Free Apple Developer Account

If you're using a **free Apple Developer account**:
- You can only register up to 3 devices per year
- Provisioning profiles expire after 7 days
- You need to reconnect and regenerate profiles periodically
- Consider upgrading to paid account ($99/year) for production apps

## Quick Commands

```bash
# Clean and rebuild
cd mobile
flutter clean
flutter pub get
cd ios
pod install
cd ..

# Open Xcode
open ios/Runner.xcworkspace

# Check devices
flutter devices

# Run on device
flutter run -d ios
```

## After Fixing

Once signing is configured:

```bash
cd mobile
./scripts/run_ios.sh
```

Or manually:
```bash
flutter run -d ios
```

## Need Help?

- Check Xcode console for detailed error messages
- Run `flutter doctor -v` to check Flutter setup
- Verify your Apple ID is signed in Xcode: Xcode → Settings → Accounts
