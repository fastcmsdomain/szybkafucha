#!/bin/bash
#
# Setup dedicated test simulators for multi-device testing
#
# Usage:
#   ./scripts/setup_test_simulators.sh
#

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

echo ""
echo "=============================================="
echo "   Setting Up Test Simulators"
echo "=============================================="
echo ""

# Simulator configuration
CLIENT_NAME="SzybkaFucha-Client"
CONTRACTOR_NAME="SzybkaFucha-Contractor"
DEVICE_TYPE="iPhone 16 Pro"

# Get latest iOS runtime
RUNTIME=$(xcrun simctl list runtimes | grep "iOS" | tail -1 | grep -oE 'com.apple.CoreSimulator.SimRuntime.[^ ]+')

if [ -z "$RUNTIME" ]; then
    log_error "No iOS runtime found"
    exit 1
fi

log_info "Using runtime: $RUNTIME"
log_info "Device type: $DEVICE_TYPE"

# Delete existing test simulators if they exist
log_info "Cleaning up existing test simulators..."
xcrun simctl delete "$CLIENT_NAME" 2>/dev/null || true
xcrun simctl delete "$CONTRACTOR_NAME" 2>/dev/null || true

# Get device type ID
DEVICE_TYPE_ID=$(xcrun simctl list devicetypes | grep "$DEVICE_TYPE" | grep -oE 'com.apple.CoreSimulator.SimDeviceType[^ ]+' | head -1 | tr -d ')')

if [ -z "$DEVICE_TYPE_ID" ]; then
    log_error "Device type '$DEVICE_TYPE' not found"
    log_info "Available device types:"
    xcrun simctl list devicetypes | grep iPhone
    exit 1
fi

log_info "Device type ID: $DEVICE_TYPE_ID"

# Create client simulator
log_info "Creating $CLIENT_NAME..."
CLIENT_UDID=$(xcrun simctl create "$CLIENT_NAME" "$DEVICE_TYPE_ID" "$RUNTIME")
log_success "Created: $CLIENT_NAME ($CLIENT_UDID)"

# Create contractor simulator
log_info "Creating $CONTRACTOR_NAME..."
CONTRACTOR_UDID=$(xcrun simctl create "$CONTRACTOR_NAME" "$DEVICE_TYPE_ID" "$RUNTIME")
log_success "Created: $CONTRACTOR_NAME ($CONTRACTOR_UDID)"

echo ""
echo "=============================================="
echo "   Test Simulators Created Successfully"
echo "=============================================="
echo ""
echo "Client Simulator:"
echo "  Name: $CLIENT_NAME"
echo "  UDID: $CLIENT_UDID"
echo ""
echo "Contractor Simulator:"
echo "  Name: $CONTRACTOR_NAME"
echo "  UDID: $CONTRACTOR_UDID"
echo ""
echo "To use these simulators, update the variables in"
echo "run_multi_device_tests.sh:"
echo ""
echo "  CLIENT_SIMULATOR=\"$CLIENT_NAME\""
echo "  CONTRACTOR_SIMULATOR=\"$CONTRACTOR_NAME\""
echo ""
