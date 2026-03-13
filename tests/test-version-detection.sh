#!/usr/bin/env bash
set -uo pipefail

# changelog-pilot version detection test suite
# Validates detect-version.sh against known fixture projects.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
DETECT_SCRIPT="$TESTS_DIR/../plugin/skills/changelog-pilot/scripts/detect-version.sh"
FIXTURES_DIR="$TESTS_DIR/fixtures"

PASS_COUNT=0
FAIL_COUNT=0
TOTAL=0

# Verify dependencies
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed."
  exit 1
fi

if [ ! -x "$DETECT_SCRIPT" ]; then
  chmod +x "$DETECT_SCRIPT" 2>/dev/null || true
  if [ ! -x "$DETECT_SCRIPT" ]; then
    echo "Error: detect-version.sh not found or not executable at $DETECT_SCRIPT"
    exit 1
  fi
fi

# Helper: run a single version detection test
# Arguments:
#   $1 - fixture directory name
#   $2 - expected version (use "" to expect empty)
#   $3 - expected version source file
#   $4 - label for display
#   $5 - (optional) "conflict" if we expect a non-empty conflicts array
run_test() {
  local fixture_name="$1"
  local expected_version="$2"
  local expected_source="$3"
  local label="$4"
  local expect_conflict="${5:-}"

  TOTAL=$((TOTAL + 1))

  local fixture_dir="$FIXTURES_DIR/$fixture_name"
  if [ ! -d "$fixture_dir" ]; then
    printf "  FAIL %-28s fixture directory not found\n" "$label:"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  # Run detection from fixture directory
  local output
  output=$(cd "$fixture_dir" && bash "$DETECT_SCRIPT" 2>/dev/null)
  local exit_code=$?

  if [ $exit_code -ne 0 ]; then
    printf "  FAIL %-28s detect-version.sh exited with code %d\n" "$label:" "$exit_code"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  # Validate JSON output
  if ! echo "$output" | jq . &>/dev/null; then
    printf "  FAIL %-28s invalid JSON output\n" "$label:"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    return
  fi

  local actual_version actual_source conflicts_count
  actual_version=$(echo "$output" | jq -r '.currentVersion')
  actual_source=$(echo "$output" | jq -r '.versionSource')
  conflicts_count=$(echo "$output" | jq '.conflicts | length')

  local errors=""

  # Check version
  if [ -n "$expected_version" ]; then
    if [ "$actual_version" != "$expected_version" ]; then
      errors="${errors}version expected=$expected_version got=$actual_version; "
    fi
  else
    # Expect empty version
    if [ -n "$actual_version" ] && [ "$actual_version" != "" ]; then
      errors="${errors}version expected=empty got=$actual_version; "
    fi
  fi

  # Check source
  if [ -n "$expected_source" ]; then
    if [ "$actual_source" != "$expected_source" ]; then
      errors="${errors}source expected=$expected_source got=$actual_source; "
    fi
  fi

  # Check conflicts
  if [ "$expect_conflict" = "conflict" ]; then
    if [ "$conflicts_count" -eq 0 ]; then
      errors="${errors}expected conflicts but got none; "
    fi
  else
    if [ "$conflicts_count" -gt 0 ]; then
      errors="${errors}unexpected conflicts (count=$conflicts_count); "
    fi
  fi

  # Verify allVersionFiles exists
  local files_count
  files_count=$(echo "$output" | jq '.allVersionFiles | length')
  if [ "$files_count" -lt 0 ] 2>/dev/null; then
    errors="${errors}allVersionFiles missing; "
  fi

  # Verify conflicts field exists (even if empty)
  if ! echo "$output" | jq -e '.conflicts' &>/dev/null; then
    errors="${errors}conflicts field missing; "
  fi

  # Report result
  if [ -z "$errors" ]; then
    local version_display=""
    if [ -n "$actual_version" ] && [ "$actual_version" != "" ]; then
      version_display=" version=$actual_version"
    fi
    printf "  PASS %-28s source=%s%s\n" "$label:" "$actual_source" "$version_display"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "  FAIL %-28s %s\n" "$label:" "$errors"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo ""
echo "  Version Detection Tests"
echo "  =========================="
echo ""
echo "  -- Core Detection --------------------------------"

#            fixture dir        version        source            label
run_test     "npm-project"      "2.3.1"        "package.json"    "npm package.json"
run_test     "flutter-project"  "1.5.0+3"      "pubspec.yaml"    "flutter pubspec.yaml"
run_test     "rust-project"     "0.8.2"        "Cargo.toml"      "rust Cargo.toml"
run_test     "python-poetry"    "3.1.0"        "pyproject.toml"  "python pyproject.toml"
run_test     "python-setup"     "2.0.0"        "setup.py"        "python setup.py"
run_test     "ruby-project"     "1.2.3"        "test-ruby.gemspec" "ruby gemspec"
run_test     "csharp-project"   "4.0.0"        "TestProject.csproj" "csharp csproj"

echo ""
echo "  -- Edge Cases ------------------------------------"

run_test     "multi-version"    "1.2.3"        "package.json"    "multi-version conflict" "conflict"
run_test     "no-version"       ""             ""                "no version field"
run_test     "pre-release"      "2.0.0-beta.1" "package.json"   "pre-release version"

echo ""
echo "  =================================================="
printf "  Results: %d/%d passed\n" "$PASS_COUNT" "$TOTAL"

if [ $FAIL_COUNT -gt 0 ]; then
  echo "  $FAIL_COUNT test(s) failed."
  exit 1
else
  echo "  All tests passed."
  exit 0
fi
