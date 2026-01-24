#!/bin/bash

# Script to check if device is connected and ready for Flutter development
# Usage: ./scripts/check_device.sh

echo "🔍 Checking Flutter device connection..."
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the mobile directory"
    echo "   cd mobile && ./scripts/check_device.sh"
    exit 1
fi

# Check Flutter installation
echo "1️⃣ Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi
echo "✅ Flutter is installed"
flutter --version | head -n 1
echo ""

# Run flutter doctor
echo "2️⃣ Running Flutter Doctor..."
flutter doctor
echo ""

# Check connected devices
echo "3️⃣ Checking connected devices..."
DEVICES=$(flutter devices)
echo "$DEVICES"
echo ""

# Check for physical devices
if echo "$DEVICES" | grep -q "physical"; then
    echo "✅ Physical device detected!"
    PHYSICAL_DEVICE=$(echo "$DEVICES" | grep "physical" | head -n 1 | awk '{print $1}')
    echo "   Device ID: $PHYSICAL_DEVICE"
    echo ""
    echo "🚀 Ready to run! Use:"
    echo "   flutter run -d $PHYSICAL_DEVICE"
    echo "   or simply: flutter run"
else
    echo "⚠️  No physical device detected"
    echo ""
    echo "For iOS:"
    echo "  - Connect iPhone via USB"
    echo "  - Trust Mac on iPhone"
    echo "  - Enable Developer Mode"
    echo ""
    echo "For Android:"
    echo "  - Enable Developer Options"
    echo "  - Enable USB Debugging"
    echo "  - Connect device via USB"
fi

echo ""
echo "4️⃣ Checking backend connection..."
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
if [ -n "$MAC_IP" ]; then
    echo "✅ Mac IP address: $MAC_IP"
    echo "   Use this IP for backend connection on physical device"
    echo "   Backend URL: http://$MAC_IP:3000"
else
    echo "⚠️  Could not detect Mac IP address"
fi

echo ""
echo "✅ Device check complete!"
