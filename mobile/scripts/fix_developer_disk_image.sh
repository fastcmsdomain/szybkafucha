#!/bin/bash

# Script to fix "developer disk image could not be mounted" error
# This error occurs when iOS version on device doesn't match Xcode support
# Usage: ./scripts/fix_developer_disk_image.sh

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fixing Developer Disk Image Error${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Error: Please run this script from the mobile directory${NC}"
    echo "   cd mobile && ./scripts/fix_developer_disk_image.sh"
    exit 1
fi

# Step 1: Check Xcode version
echo -e "${BLUE}1️⃣ Checking Xcode version...${NC}"
XCODE_VERSION=$(xcodebuild -version 2>&1 | head -1)
echo "$XCODE_VERSION"
XCODE_MAJOR=$(echo "$XCODE_VERSION" | grep -oE '[0-9]+\.[0-9]+' | head -1)
echo -e "${GREEN}✅ Xcode ${XCODE_MAJOR} installed${NC}"
echo ""

# Step 2: Check connected devices
echo -e "${BLUE}2️⃣ Checking connected iOS devices...${NC}"
DEVICES=$(flutter devices 2>&1)
IOS_DEVICE=$(echo "$DEVICES" | grep -E "wireless.*ios|physical.*ios" || echo "$DEVICES" | grep "ios.*iOS" | head -1)

if [ -z "$IOS_DEVICE" ]; then
    echo -e "${YELLOW}⚠️  No iOS device detected via Flutter${NC}"
    echo -e "${YELLOW}   Checking via Xcode...${NC}"
    
    # Check via xcrun
    XCODE_DEVICES=$(xcrun xctrace list devices 2>&1 | grep -i "iphone\|ipad" | grep -v "Simulator" || true)
    if [ -z "$XCODE_DEVICES" ]; then
        echo -e "${RED}❌ No physical iOS device found${NC}"
        echo ""
        echo -e "${YELLOW}Please:${NC}"
        echo "   1. Connect iPhone to Mac via USB cable"
        echo "   2. Unlock iPhone"
        echo "   3. Trust Mac on iPhone"
        echo "   4. Run this script again"
        exit 1
    else
        echo -e "${GREEN}✅ Found devices via Xcode:${NC}"
        echo "$XCODE_DEVICES"
    fi
else
    echo -e "${GREEN}✅ Found iOS device:${NC}"
    echo "$IOS_DEVICE"
    
    # Extract iOS version
    IOS_VERSION=$(echo "$IOS_DEVICE" | grep -oE 'iOS [0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "$IOS_DEVICE" | grep -oE 'iOS [0-9]+\.[0-9]+' | head -1)
    if [ -n "$IOS_VERSION" ]; then
        echo -e "${YELLOW}   Device iOS version: ${IOS_VERSION}${NC}"
    fi
fi
echo ""

# Step 3: Check available iOS runtimes
echo -e "${BLUE}3️⃣ Checking available iOS runtimes in Xcode...${NC}"
RUNTIMES=$(xcrun simctl list runtimes 2>&1 | grep iOS || true)
if [ -n "$RUNTIMES" ]; then
    echo "$RUNTIMES"
else
    echo -e "${YELLOW}⚠️  No iOS runtimes found${NC}"
fi
echo ""

# Step 4: Solutions
echo -e "${BLUE}4️⃣ Solutions to try:${NC}"
echo ""
echo -e "${YELLOW}Solution 1: Update Xcode (Recommended)${NC}"
echo "   1. Open App Store"
echo "   2. Search for 'Xcode'"
echo "   3. Click 'Update' if available"
echo "   4. Or download latest from: https://developer.apple.com/xcode/"
echo ""
echo -e "${YELLOW}Solution 2: Download Additional Components${NC}"
echo "   1. Open Xcode"
echo "   2. Go to: Xcode → Settings → Platforms"
echo "   3. Download latest iOS platform if available"
echo ""
echo -e "${YELLOW}Solution 3: Connect via USB (Not Wireless)${NC}"
echo "   Wireless connection may cause this error"
echo "   1. Disconnect wireless connection"
echo "   2. Connect iPhone via USB cable"
echo "   3. Trust Mac on iPhone"
echo "   4. Try running app again"
echo ""
echo -e "${YELLOW}Solution 4: Check Device iOS Version${NC}"
echo "   Your device shows iOS 26.2.1 which seems unusual"
echo "   1. On iPhone: Settings → General → About"
echo "   2. Check actual iOS version"
echo "   3. If it's a beta, consider updating Xcode or device"
echo ""

# Step 5: Try to download platform
echo -e "${BLUE}5️⃣ Attempting to download iOS platform components...${NC}"
echo -e "${YELLOW}   This may take a few minutes...${NC}"
xcodebuild -downloadPlatform iOS 2>&1 | grep -E "Downloading|Finding|available|Error" || echo -e "${GREEN}✅ Platform check complete${NC}"
echo ""

# Step 6: Check Xcode command line tools
echo -e "${BLUE}6️⃣ Checking Xcode command line tools...${NC}"
if xcode-select -p &> /dev/null; then
    XCODE_PATH=$(xcode-select -p)
    echo -e "${GREEN}✅ Command line tools: ${XCODE_PATH}${NC}"
else
    echo -e "${RED}❌ Command line tools not configured${NC}"
    echo "   Run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
fi
echo ""

# Step 7: Recommendations
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Recommended Actions:${NC}"
echo ""
echo "1. ${YELLOW}Connect iPhone via USB${NC} (not wireless)"
echo "2. ${YELLOW}Update Xcode${NC} to latest version from App Store"
echo "3. ${YELLOW}Check iPhone iOS version${NC} - iOS 26.2.1 seems unusual"
echo "4. ${YELLOW}In Xcode:${NC} Window → Devices and Simulators"
echo "   - Select your iPhone"
echo "   - Check if it shows any errors"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}After trying these solutions, run:${NC}"
echo "   ./scripts/run_ios.sh"
echo ""
