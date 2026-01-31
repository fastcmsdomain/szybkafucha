#!/bin/bash
#
# Multi-Device Integration Test Runner
# Runs integration tests on two iOS simulators simultaneously
#
# Usage:
#   ./scripts/run_multi_device_tests.sh [scenario_name]
#
# Examples:
#   ./scripts/run_multi_device_tests.sh                    # Run all scenarios
#   ./scripts/run_multi_device_tests.sh full_lifecycle     # Run specific scenario
#   VERBOSE=true ./scripts/run_multi_device_tests.sh       # Verbose output
#

set -e

# ============================================
# Configuration
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$(cd "$MOBILE_DIR/../backend" && pwd)"
SYNC_DIR="/tmp/szybkafucha_tests"

# Simulator names (adjust to match your setup)
CLIENT_SIMULATOR="iPhone 16 Pro"
CONTRACTOR_SIMULATOR="iPhone 16"

# Backend URL
BACKEND_URL="http://localhost:3000"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# ============================================
# Cleanup function
# ============================================
cleanup() {
    log_info "Cleaning up..."

    # Kill background processes
    if [ ! -z "$CLIENT_PID" ]; then
        kill $CLIENT_PID 2>/dev/null || true
    fi
    if [ ! -z "$CONTRACTOR_PID" ]; then
        kill $CONTRACTOR_PID 2>/dev/null || true
    fi

    # Clear sync directory
    rm -rf "$SYNC_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# ============================================
# Parse arguments
# ============================================
SCENARIO=${1:-"full_lifecycle"}
VERBOSE=${VERBOSE:-false}

# ============================================
# Banner
# ============================================
echo ""
echo "=============================================="
echo "   Szybka Fucha Multi-Device Integration Tests"
echo "=============================================="
echo ""
log_info "Scenario: $SCENARIO"
log_info "Client Simulator: $CLIENT_SIMULATOR"
log_info "Contractor Simulator: $CONTRACTOR_SIMULATOR"
echo ""

# ============================================
# Step 1: Check prerequisites
# ============================================
log_step "Step 1: Checking prerequisites..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    log_error "Flutter is not installed or not in PATH"
    exit 1
fi
log_success "Flutter found"

# Check if backend is running
if curl -s "${BACKEND_URL}/api/v1/health" > /dev/null 2>&1; then
    log_success "Backend is running at $BACKEND_URL"
else
    log_error "Backend is not running at $BACKEND_URL"
    log_info "Start the backend with: cd backend && npm run start:dev"
    exit 1
fi

# ============================================
# Step 2: Reset database
# ============================================
log_step "Step 2: Resetting database with fresh seed data..."

cd "$BACKEND_DIR"
if npm run seed:fresh > /dev/null 2>&1; then
    log_success "Database seeded successfully"
else
    log_warning "Database seeding failed (may already be fresh)"
fi

# ============================================
# Step 3: Find and boot simulators
# ============================================
log_step "Step 3: Preparing simulators..."

# Get UDIDs (use exact match with " (" to avoid "iPhone 16" matching "iPhone 16 Pro")
CLIENT_UDID=$(xcrun simctl list devices available | grep "$CLIENT_SIMULATOR (" | grep -oE '[A-F0-9-]{36}' | head -1)
CONTRACTOR_UDID=$(xcrun simctl list devices available | grep "$CONTRACTOR_SIMULATOR (" | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -z "$CLIENT_UDID" ]; then
    log_error "Client simulator '$CLIENT_SIMULATOR' not found"
    log_info "Available simulators:"
    xcrun simctl list devices available | grep iPhone
    exit 1
fi

if [ -z "$CONTRACTOR_UDID" ]; then
    log_error "Contractor simulator '$CONTRACTOR_SIMULATOR' not found"
    log_info "Available simulators:"
    xcrun simctl list devices available | grep iPhone
    exit 1
fi

log_info "Client UDID: $CLIENT_UDID"
log_info "Contractor UDID: $CONTRACTOR_UDID"

# Boot simulators
log_info "Booting simulators..."
xcrun simctl boot "$CLIENT_UDID" 2>/dev/null || true
xcrun simctl boot "$CONTRACTOR_UDID" 2>/dev/null || true

# Wait for simulators to be ready
sleep 5
log_success "Simulators ready"

# ============================================
# Step 4: Prepare sync directory
# ============================================
log_step "Step 4: Preparing sync directory..."
rm -rf "$SYNC_DIR"
mkdir -p "$SYNC_DIR"
log_success "Sync directory ready: $SYNC_DIR"

# ============================================
# Step 5: Run tests
# ============================================
log_step "Step 5: Running integration tests..."

cd "$MOBILE_DIR"

# Determine test file
TEST_FILE="integration_test/scenarios/${SCENARIO}_test.dart"
if [ ! -f "$TEST_FILE" ]; then
    log_error "Test file not found: $TEST_FILE"
    log_info "Available scenarios:"
    ls -1 integration_test/scenarios/ 2>/dev/null | sed 's/_test.dart//' | sed 's/^/  /'
    exit 1
fi

log_info "Running: $TEST_FILE"

# Create log files
CLIENT_LOG="$SYNC_DIR/client_output.log"
CONTRACTOR_LOG="$SYNC_DIR/contractor_output.log"

# Run client test
log_info "Starting client test on $CLIENT_SIMULATOR..."
DEVICE_ROLE=client flutter test \
    "$TEST_FILE" \
    --device-id="$CLIENT_UDID" \
    --dart-define=DEVICE_ROLE=client \
    > "$CLIENT_LOG" 2>&1 &
CLIENT_PID=$!

# Small delay to avoid race conditions
sleep 2

# Run contractor test
log_info "Starting contractor test on $CONTRACTOR_SIMULATOR..."
DEVICE_ROLE=contractor flutter test \
    "$TEST_FILE" \
    --device-id="$CONTRACTOR_UDID" \
    --dart-define=DEVICE_ROLE=contractor \
    > "$CONTRACTOR_LOG" 2>&1 &
CONTRACTOR_PID=$!

# ============================================
# Step 6: Wait for tests to complete
# ============================================
log_step "Step 6: Waiting for tests to complete..."

# Monitor progress
while kill -0 $CLIENT_PID 2>/dev/null || kill -0 $CONTRACTOR_PID 2>/dev/null; do
    # Show last sync marker
    if [ -d "$SYNC_DIR" ]; then
        LAST_MARKER=$(ls -t "$SYNC_DIR"/*.log 2>/dev/null | head -1)
        if [ ! -z "$LAST_MARKER" ] && [ "$VERBOSE" = "true" ]; then
            tail -1 "$LAST_MARKER" 2>/dev/null || true
        fi
    fi
    sleep 2
done

# Get exit codes
wait $CLIENT_PID 2>/dev/null
CLIENT_EXIT=$?

wait $CONTRACTOR_PID 2>/dev/null
CONTRACTOR_EXIT=$?

# ============================================
# Step 7: Report results
# ============================================
echo ""
echo "=============================================="
echo "                TEST RESULTS"
echo "=============================================="
echo ""

# Client results
if [ $CLIENT_EXIT -eq 0 ]; then
    log_success "Client tests: PASSED"
else
    log_error "Client tests: FAILED (exit code: $CLIENT_EXIT)"
    if [ "$VERBOSE" = "true" ]; then
        echo ""
        echo "--- Client Output (last 30 lines) ---"
        tail -30 "$CLIENT_LOG"
        echo ""
    fi
fi

# Contractor results
if [ $CONTRACTOR_EXIT -eq 0 ]; then
    log_success "Contractor tests: PASSED"
else
    log_error "Contractor tests: FAILED (exit code: $CONTRACTOR_EXIT)"
    if [ "$VERBOSE" = "true" ]; then
        echo ""
        echo "--- Contractor Output (last 30 lines) ---"
        tail -30 "$CONTRACTOR_LOG"
        echo ""
    fi
fi

echo ""
echo "=============================================="

# Overall result
if [ $CLIENT_EXIT -eq 0 ] && [ $CONTRACTOR_EXIT -eq 0 ]; then
    echo -e "${GREEN}"
    echo "  ✅ ALL TESTS PASSED"
    echo -e "${NC}"
    echo "=============================================="
    exit 0
else
    echo -e "${RED}"
    echo "  ❌ SOME TESTS FAILED"
    echo -e "${NC}"
    echo "=============================================="
    echo ""
    log_info "Full logs available at:"
    log_info "  Client: $CLIENT_LOG"
    log_info "  Contractor: $CONTRACTOR_LOG"
    exit 1
fi
