#!/bin/bash

# Quick run script for Szybka Fucha Android app
# Usage: ./scripts/run_android.sh
# Or from project root: cd mobile && ./scripts/run_android.sh

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
    echo "   cd mobile && ./scripts/run_android.sh"
    exit 1
fi

# Configuration
EMULATOR_NAME="Pixel_7_API_34"
EMULATOR_ID="emulator-5554"
MAX_WAIT_TIME=120  # Maximum wait time in seconds (2 minutes)

echo -e "${BLUE}🚀 Szybka Fucha - Android Quick Run${NC}"
echo ""

# Step 1: Check Flutter installation
echo -e "${BLUE}1️⃣ Checking Flutter installation...${NC}"
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Flutter is installed${NC}"
echo ""

# Step 2: Check if emulator is already running
echo -e "${BLUE}2️⃣ Checking Android emulator status...${NC}"
if adb devices | grep -q "$EMULATOR_ID.*device$"; then
    echo -e "${GREEN}✅ Android emulator is already running${NC}"
    EMULATOR_RUNNING=true
else
    echo -e "${YELLOW}⚠️  Android emulator is not running${NC}"
    EMULATOR_RUNNING=false
fi
echo ""

# Step 3: Launch emulator if needed
if [ "$EMULATOR_RUNNING" = false ]; then
    echo -e "${BLUE}3️⃣ Launching Android emulator ($EMULATOR_NAME)...${NC}"
    flutter emulators --launch "$EMULATOR_NAME" > /dev/null 2>&1 &
    EMULATOR_PID=$!
    echo -e "${YELLOW}⏳ Waiting for emulator to boot (this may take 30-60 seconds)...${NC}"
    
    # Wait for emulator to be ready
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt $MAX_WAIT_TIME ]; do
        sleep 5
        WAIT_COUNT=$((WAIT_COUNT + 5))
        
        if adb devices | grep -q "$EMULATOR_ID.*device$"; then
            echo -e "${GREEN}✅ Emulator is ready!${NC}"
            break
        fi
        
        # Show progress every 15 seconds
        if [ $((WAIT_COUNT % 15)) -eq 0 ]; then
            echo -e "${YELLOW}   Still booting... (${WAIT_COUNT}s / ${MAX_WAIT_TIME}s)${NC}"
        fi
    done
    
    # Check if emulator is ready
    if ! adb devices | grep -q "$EMULATOR_ID.*device$"; then
        echo -e "${RED}❌ Emulator failed to start within ${MAX_WAIT_TIME} seconds${NC}"
        echo -e "${YELLOW}   Try launching it manually: flutter emulators --launch $EMULATOR_NAME${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}3️⃣ Skipping emulator launch (already running)${NC}"
fi
echo ""

# Step 4: Verify device is available to Flutter
echo -e "${BLUE}4️⃣ Verifying Flutter device connection...${NC}"
FLUTTER_DEVICES=$(flutter devices)
if echo "$FLUTTER_DEVICES" | grep -q "$EMULATOR_ID.*android"; then
    echo -e "${GREEN}✅ Device is ready for Flutter${NC}"
else
    echo -e "${YELLOW}⚠️  Device may not be fully ready, but continuing anyway...${NC}"
fi
echo ""

# Step 5: Get dependencies (quick check)
echo -e "${BLUE}5️⃣ Checking dependencies...${NC}"
if [ ! -d ".dart_tool" ] || [ ! -f "pubspec.lock" ]; then
    echo -e "${YELLOW}   Running flutter pub get...${NC}"
    flutter pub get > /dev/null 2>&1
    echo -e "${GREEN}✅ Dependencies ready${NC}"
else
    echo -e "${GREEN}✅ Dependencies already installed${NC}"
fi
echo ""

# Step 6: Run the app
echo -e "${BLUE}6️⃣ Launching Szybka Fucha app...${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo -e "   • Press 'r' for hot reload"
echo -e "   • Press 'R' for hot restart"
echo -e "   • Press 'q' to quit"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Run Flutter app
flutter run -d "$EMULATOR_ID"
