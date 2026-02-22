#!/bin/bash

# Quick run script for Szybka Fucha iOS app on physical device
# Usage: ./scripts/run_ios.sh
# Or from project root: cd mobile && ./scripts/run_ios.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Please run this script from the mobile directory${NC}"
    echo "   cd mobile && ./scripts/run_ios.sh"
    exit 1
fi

echo -e "${BLUE}🚀 Szybka Fucha - iOS Quick Run${NC}"
echo ""

# Step 1: Check Flutter installation
echo -e "${BLUE}1️⃣ Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter is installed${NC}"
echo ""

# Step 2: Check for connected iOS devices
echo -e "${BLUE}2️⃣ Checking for connected iOS devices...${NC}"
FLUTTER_DEVICES=$(flutter devices)
IOS_DEVICES=$(echo "$FLUTTER_DEVICES" | grep -E "ios.*physical|wireless.*ios" || true)

if [ -z "$IOS_DEVICES" ]; then
    echo -e "${RED}❌ No physical iOS device found${NC}"
    echo ""
    echo -e "${YELLOW}📱 Setup Instructions:${NC}"
    echo "   1. Connect iPhone to Mac via USB cable"
    echo "   2. Unlock iPhone and tap 'Trust This Computer'"
    echo "   3. Enable Developer Mode:"
    echo "      Settings → Privacy & Security → Developer Mode → ON"
    echo "      (iPhone will restart)"
    echo "   4. Run this script again"
    echo ""
    echo -e "${YELLOW}   Or connect wirelessly:${NC}"
    echo "   1. Connect iPhone via USB first"
    echo "   2. In Xcode: Window → Devices and Simulators"
    echo "   3. Select your iPhone → Check 'Connect via network'"
    echo "   4. Disconnect USB cable"
    echo ""
    exit 1
fi

# Extract device ID (first physical/wireless iOS device)
# Device ID format: 00008140-001574140189801C (UUID format)
DEVICE_ID=$(echo "$IOS_DEVICES" | head -n 1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -n 1)

if [ -z "$DEVICE_ID" ]; then
    # Try alternative pattern - look for device name and ID
    DEVICE_ID=$(echo "$IOS_DEVICES" | head -n 1 | awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9A-F-]{36,}$/) print $i}' | head -n 1)
fi

if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}⚠️  Could not extract device ID, will use 'ios' selector${NC}"
    DEVICE_ID="ios"
else
    echo -e "${GREEN}✅ Found iOS device: ${DEVICE_ID}${NC}"
fi

echo ""
echo "$FLUTTER_DEVICES"
echo ""

# Step 3: Check Xcode and code signing
echo -e "${BLUE}3️⃣ Checking Xcode setup...${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed${NC}"
    echo "   Please install Xcode from the App Store"
    exit 1
fi
echo -e "${GREEN}✅ Xcode is installed${NC}"

# Check if signing is configured
echo -e "${YELLOW}   Checking code signing...${NC}"
if [ ! -d "ios/Runner.xcworkspace" ] && [ ! -f "ios/Runner.xcworkspace" ]; then
    echo -e "${RED}❌ iOS workspace not found${NC}"
    exit 1
fi

# Try to check signing (this might fail, but that's okay)
SIGNING_CHECK=$(xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -showBuildSettings 2>&1 | grep -i "codeSign" || true)
if echo "$SIGNING_CHECK" | grep -q "CODE_SIGN"; then
    echo -e "${GREEN}✅ Code signing configured${NC}"
else
    echo -e "${YELLOW}⚠️  Code signing may need configuration${NC}"
    echo -e "${YELLOW}   If build fails, open Xcode and configure signing:${NC}"
    echo "   open ios/Runner.xcworkspace"
    echo "   Then: Runner → Signing & Capabilities → Select Team"
fi
echo ""

# Step 4: Get dependencies
echo -e "${BLUE}4️⃣ Checking dependencies...${NC}"
if [ ! -d ".dart_tool" ] || [ ! -f "pubspec.lock" ]; then
    echo -e "${YELLOW}   Running flutter pub get...${NC}"
    flutter pub get > /dev/null 2>&1
    echo -e "${GREEN}✅ Dependencies ready${NC}"
else
    echo -e "${GREEN}✅ Dependencies already installed${NC}"
fi

# Check iOS pods
if [ ! -d "ios/Pods" ]; then
    echo -e "${YELLOW}   Installing iOS pods...${NC}"
    cd ios
    pod install > /dev/null 2>&1 || {
        echo -e "${YELLOW}   Pod install may need manual run: cd ios && pod install${NC}"
    }
    cd ..
fi
echo ""

# Step 5: Get Mac IP for backend connection (if needed)
echo -e "${BLUE}5️⃣ Network configuration...${NC}"
MAC_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)
if [ -n "$MAC_IP" ]; then
    echo -e "${GREEN}✅ Mac IP address: ${MAC_IP}${NC}"
    echo -e "${YELLOW}   💡 If backend connection fails, use this IP instead of localhost${NC}"
    echo -e "${YELLOW}   Backend URL: http://${MAC_IP}:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Could not detect Mac IP address${NC}"
fi
echo ""

# Step 6: Run the app
echo -e "${BLUE}6️⃣ Launching Szybka Fucha app on iPhone...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo -e "   • Press 'r' for hot reload"
echo -e "   • Press 'R' for hot restart"
echo -e "   • Press 'q' to quit"
echo ""
echo -e "${YELLOW}📱 Device: ${DEVICE_ID}${NC}"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Run Flutter app
if [ "$DEVICE_ID" = "ios" ]; then
    flutter run -d ios
else
    flutter run -d "$DEVICE_ID"
fi
