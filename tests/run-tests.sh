#!/usr/bin/env bash
set -uo pipefail

# changelog-pilot — master test runner

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
EXIT_CODE=0

bash "$TESTS_DIR/test-version-detection.sh" || EXIT_CODE=1
echo ""
bash "$TESTS_DIR/test-commit-detection.sh" || EXIT_CODE=1

exit $EXIT_CODE
