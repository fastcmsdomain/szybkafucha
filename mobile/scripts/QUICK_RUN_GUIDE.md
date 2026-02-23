# Quick Run Guide - Szybka Fucha Mobile App

## 🚀 Quick Commands

### Run on Physical iPhone

```bash
# From project root
cd mobile
./scripts/run_ios.sh

# Or from mobile directory
./scripts/run_ios.sh
```

### Run on Android Emulator

```bash
# From project root
cd mobile
./scripts/run_android.sh

# Or from mobile directory
./scripts/run_android.sh
```

---

## 📱 iPhone Setup (First Time Only)

### Step 1: Connect iPhone
1. Connect iPhone to Mac via USB cable
2. Unlock iPhone
3. Tap **"Trust This Computer"** when prompted
4. Enter iPhone passcode

### Step 2: Enable Developer Mode
1. Open **Settings** on iPhone
2. Go to **Privacy & Security**
3. Scroll down to **Developer Mode**
4. Toggle **Developer Mode** ON
5. iPhone will restart

### Step 3: Configure Code Signing
```bash
open mobile/ios/Runner.xcworkspace
```

In Xcode:
1. Select **Runner** project (left sidebar)
2. Select **Runner** target
3. Go to **Signing & Capabilities** tab
4. Select your **Team** (your Apple ID)
5. Xcode will automatically create provisioning profile

### Step 4: Run the App
```bash
cd mobile
./scripts/run_ios.sh
```

---

## 🔌 Wireless Connection (Optional)

You **can’t use a physical iPhone as an iOS Simulator**. What you *can* do is run the app on a **real iPhone over Wi‑Fi** (wireless debugging).

After a first USB connection (pairing), you can connect wirelessly:

1. Connect iPhone via USB first
2. Open Xcode: `open mobile/ios/Runner.xcworkspace`
3. Go to: **Window** → **Devices and Simulators**
4. Select your iPhone
5. Check **"Connect via network"**
6. Make sure your Mac and iPhone are on the same Wi‑Fi network
7. Disconnect USB cable
8. iPhone will now appear as "wireless" in `flutter devices`

Run the app on the wireless device:
```bash
cd mobile
./scripts/run_ios.sh

# Or manually:
flutter devices
flutter run -d <iphone-device-id>
```

---

## 🐛 Troubleshooting

### iPhone Not Detected
- Make sure iPhone is unlocked
- Check USB cable connection
- Restart iPhone and Mac
- Run: `flutter devices`

### Code Signing Error
```bash
open mobile/ios/Runner.xcworkspace
# Fix signing in Xcode: Runner → Signing & Capabilities → Select Team
```

### Developer Mode Not Showing
- Make sure iPhone is connected via USB
- Trust the Mac on iPhone
- Restart iPhone

### Build Fails
```bash
cd mobile
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run -d ios
```

---

## ⌨️ While App is Running

- Press `r` → Hot Reload (apply changes)
- Press `R` → Hot Restart (full restart)
- Press `q` → Quit app

---

## 📚 More Information

- Detailed guide: `mobile/docs/RUNNING_ON_PHYSICAL_DEVICE.md`
- Quick start: `mobile/docs/QUICK_START_DEVICE.md`
