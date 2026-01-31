#!/bin/bash
#
# Run a specific test scenario
#
# Usage:
#   ./scripts/run_scenario.sh <scenario_name>
#
# Examples:
#   ./scripts/run_scenario.sh full_lifecycle
#   ./scripts/run_scenario.sh client_cancel
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIO=$1

if [ -z "$SCENARIO" ]; then
    echo "Usage: $0 <scenario_name>"
    echo ""
    echo "Available scenarios:"
    ls -1 "$SCRIPT_DIR/../integration_test/scenarios/" 2>/dev/null | sed 's/_test.dart//' | sed 's/^/  /'
    exit 1
fi

"$SCRIPT_DIR/run_multi_device_tests.sh" "$SCENARIO"
