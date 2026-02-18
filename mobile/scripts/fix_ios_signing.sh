#!/bin/bash

# Script to fix iOS code signing issues
# This will help register your device and fix provisioning profiles
# Usage: ./scripts/fix_ios_signing.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing iOS Code Signing${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Please run this script from the mobile directory${NC}"
    echo "   cd mobile && ./scripts/fix_ios_signing.sh"
    exit 1
fi

# Step 1: Check connected devices
echo -e "${BLUE}1️⃣ Checking connected iOS devices...${NC}"
DEVICES=$(flutter devices 2>&1)
IOS_PHYSICAL=$(echo "$DEVICES" | grep -E "wireless.*ios|physical.*ios" || true)

if [ -z "$IOS_PHYSICAL" ]; then
    echo -e "${RED}❌ No physical iOS device found${NC}"
    echo ""
    echo -e "${YELLOW}Please:${NC}"
    echo "   1. Connect iPhone to Mac via USB"
    echo "   2. Unlock iPhone and trust Mac"
    echo "   3. Run this script again"
    exit 1
fi

echo -e "${GREEN}✅ Found iOS device${NC}"
echo "$IOS_PHYSICAL"
echo ""

# Step 2: Open Xcode to register device
echo -e "${BLUE}2️⃣ Opening Xcode to register device...${NC}"
echo -e "${YELLOW}   Follow these steps in Xcode:${NC}"
echo ""
echo "   1. In Xcode, go to: Window → Devices and Simulators"
echo "   2. Select your iPhone from the left sidebar"
echo "   3. Xcode will automatically register your device"
echo ""
echo "   4. Then go to: Runner project → Signing & Capabilities"
echo "   5. Select your Team (Apple ID)"
echo "   6. Check 'Automatically manage signing'"
echo "   7. Xcode will create provisioning profile automatically"
echo ""

read -p "Press Enter when you've completed the steps in Xcode..."

# Step 3: Clean build
echo ""
echo -e "${BLUE}3️⃣ Cleaning build...${NC}"
flutter clean > /dev/null 2>&1
echo -e "${GREEN}✅ Cleaned${NC}"

# Step 4: Get dependencies
echo ""
echo -e "${BLUE}4️⃣ Getting dependencies...${NC}"
flutter pub get > /dev/null 2>&1
echo -e "${GREEN}✅ Dependencies ready${NC}"

# Step 5: Install pods
echo ""
echo -e "${BLUE}5️⃣ Installing iOS pods...${NC}"
cd ios
pod install > /dev/null 2>&1 || {
    echo -e "${YELLOW}⚠️  Pod install had warnings, but continuing...${NC}"
}
cd ..
echo -e "${GREEN}✅ Pods installed${NC}"

# Step 6: Verify signing
echo ""
echo -e "${BLUE}6️⃣ Verifying code signing...${NC}"
SIGNING_CHECK=$(xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -showBuildSettings 2>&1 | grep -E "DEVELOPMENT_TEAM|CODE_SIGN" | head -5)

if echo "$SIGNING_CHECK" | grep -q "DEVELOPMENT_TEAM"; then
    TEAM=$(echo "$SIGNING_CHECK" | grep "DEVELOPMENT_TEAM" | head -1 | awk -F'=' '{print $2}' | xargs)
    echo -e "${GREEN}✅ Development Team: ${TEAM}${NC}"
else
    echo -e "${YELLOW}⚠️  Could not verify team, but continuing...${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "   1. Make sure your iPhone is connected"
echo "   2. Run: ./scripts/run_ios.sh"
echo "   3. Or run: flutter run -d ios"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
