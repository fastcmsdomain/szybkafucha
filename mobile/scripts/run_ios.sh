#!/bin/bash

# Quick run script for Szybka Fucha on physical iOS devices (iPhone & iPad)
# Usage:
#   ./scripts/run_ios.sh          # auto-selects first physical device
#   ./scripts/run_ios.sh 2        # selects device #2 from list
#   DEV_SERVER_URL=http://192.168.1.50:3000 ./scripts/run_ios.sh  # manual IP

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: Run this script from the mobile directory${NC}"
    echo "   cd mobile && ./scripts/run_ios.sh"
    exit 1
fi

echo -e "${BLUE}${BOLD}Szybka Fucha - iOS Physical Device Runner${NC}"
echo ""

# ── 1. Flutter check ─────────────────────────────────────────
echo -e "${BLUE}1/6 Flutter installation${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed or not in PATH${NC}"
    exit 1
fi
echo -e "${GREEN}  Flutter OK${NC}"

# ── 2. Detect physical iOS devices ──────────────────────────
echo -e "${BLUE}2/6 Connected devices${NC}"
FLUTTER_DEVICES=$(flutter devices 2>/dev/null)

# Collect physical iOS devices (iPhone and iPad)
PHYSICAL_LINES=()
while IFS= read -r line; do
    PHYSICAL_LINES+=("$line")
done < <(echo "$FLUTTER_DEVICES" | grep -iE '(iphone|ipad|ios)' | grep -iv simulator || true)

if [ ${#PHYSICAL_LINES[@]} -eq 0 ]; then
    echo -e "${RED}No physical iOS device found${NC}"
    echo ""
    echo -e "${YELLOW}Setup instructions:${NC}"
    echo "  1. Connect iPhone/iPad to Mac via USB"
    echo "  2. Unlock the device and tap 'Trust This Computer'"
    echo "  3. Enable Developer Mode:"
    echo "     Settings > Privacy & Security > Developer Mode > ON"
    echo "  4. Run this script again"
    echo ""
    echo -e "${YELLOW}Or connect wirelessly:${NC}"
    echo "  1. Connect via USB first"
    echo "  2. In Xcode: Window > Devices and Simulators"
    echo "  3. Select device > Check 'Connect via network'"
    echo "  4. Disconnect USB cable"
    exit 1
fi

# Display devices and let user pick
echo ""
for i in "${!PHYSICAL_LINES[@]}"; do
    echo -e "  ${GREEN}[$((i+1))]${NC} ${PHYSICAL_LINES[$i]}"
done
echo ""

SELECTED_IDX=0
if [ ${#PHYSICAL_LINES[@]} -gt 1 ]; then
    if [ -n "${1:-}" ] && [ "$1" -ge 1 ] 2>/dev/null && [ "$1" -le ${#PHYSICAL_LINES[@]} ]; then
        SELECTED_IDX=$(($1 - 1))
    else
        echo -n "Select device [1-${#PHYSICAL_LINES[@]}] (default 1): "
        read -r CHOICE
        if [ -n "$CHOICE" ] && [ "$CHOICE" -ge 1 ] 2>/dev/null && [ "$CHOICE" -le ${#PHYSICAL_LINES[@]} ]; then
            SELECTED_IDX=$((CHOICE - 1))
        fi
    fi
fi

SELECTED_LINE="${PHYSICAL_LINES[$SELECTED_IDX]}"
echo -e "${GREEN}  Selected: ${SELECTED_LINE}${NC}"

# Extract device ID – flutter devices outputs patterns like:
#   Si phone (mobile) • 00008140-001574140189801C • ios • iOS 18.3.2
# The ID is between bullet characters (•)
DEVICE_ID=$(echo "$SELECTED_LINE" | sed 's/•/|/g' | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')

if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}  Could not parse device ID, using 'ios' selector${NC}"
    DEVICE_ID="ios"
fi

echo -e "${GREEN}  Device ID: ${DEVICE_ID}${NC}"
echo ""

# ── 3. Xcode & code signing ─────────────────────────────────
echo -e "${BLUE}3/6 Xcode setup${NC}"
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Xcode is not installed${NC}"
    exit 1
fi
echo -e "${GREEN}  Xcode OK${NC}"

SIGNING_CHECK=$(xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -showBuildSettings 2>&1 | grep -i "CODE_SIGN" || true)
if echo "$SIGNING_CHECK" | grep -q "CODE_SIGN"; then
    echo -e "${GREEN}  Code signing configured${NC}"
else
    echo -e "${YELLOW}  Code signing may need configuration${NC}"
    echo "  If build fails: open ios/Runner.xcworkspace > Runner > Signing & Capabilities > Select Team"
fi
echo ""

# ── 4. Dependencies ─────────────────────────────────────────
echo -e "${BLUE}4/6 Dependencies${NC}"
if [ ! -d ".dart_tool" ] || [ ! -f "pubspec.lock" ]; then
    echo -e "${YELLOW}  Running flutter pub get…${NC}"
    flutter pub get > /dev/null 2>&1
fi
echo -e "${GREEN}  Dart packages OK${NC}"

if [ ! -d "ios/Pods" ]; then
    echo -e "${YELLOW}  Installing CocoaPods…${NC}"
    (cd ios && pod install > /dev/null 2>&1) || echo -e "${YELLOW}  pod install may need manual run: cd ios && pod install${NC}"
fi
echo -e "${GREEN}  iOS pods OK${NC}"
echo ""

# ── 5. Network / backend URL ────────────────────────────────
echo -e "${BLUE}5/6 Network configuration${NC}"
MAC_IP=$(
    ipconfig getifaddr en0 2>/dev/null || \
    ipconfig getifaddr en1 2>/dev/null || \
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1
)

DEV_SERVER_URL_ARG=()
if [ -n "${DEV_SERVER_URL:-}" ]; then
    DEV_SERVER_URL_ARG=(--dart-define="DEV_SERVER_URL=${DEV_SERVER_URL}")
    echo -e "${GREEN}  Using DEV_SERVER_URL=${DEV_SERVER_URL}${NC}"
elif [ -n "$MAC_IP" ]; then
    DEV_SERVER_URL_ARG=(--dart-define="DEV_SERVER_URL=http://${MAC_IP}:3000")
    echo -e "${GREEN}  Mac IP: ${MAC_IP}${NC}"
    echo -e "${GREEN}  Backend URL: http://${MAC_IP}:3000${NC}"
else
    echo -e "${YELLOW}  Could not detect Mac IP – the app will auto-discover on LAN${NC}"
fi
echo ""

# ── 6. Launch ────────────────────────────────────────────────
echo -e "${BLUE}6/6 Launching app${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${BOLD}Device:${NC} ${DEVICE_ID}"
if [ ${#DEV_SERVER_URL_ARG[@]} -gt 0 ]; then
    echo -e "  ${BOLD}Server:${NC} ${DEV_SERVER_URL_ARG[0]#--dart-define=DEV_SERVER_URL=}"
else
    echo -e "  ${BOLD}Server:${NC} auto-discover on LAN"
fi
echo ""
echo -e "  ${YELLOW}r${NC} Hot reload   ${YELLOW}R${NC} Hot restart   ${YELLOW}q${NC} Quit"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

flutter run -d "$DEVICE_ID" "${DEV_SERVER_URL_ARG[@]}"
