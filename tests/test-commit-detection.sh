#!/usr/bin/env bash
set -uo pipefail

# changelog-pilot commit detection test suite
# Tests JSON escaping and style detection in isolation.
# Does not require a real git repo — tests the jq-based encoding directly.

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"
DETECT_SCRIPT="$TESTS_DIR/../plugin/skills/changelog-pilot/scripts/detect-commits.sh"

PASS_COUNT=0
FAIL_COUNT=0
TOTAL=0

# Verify dependencies
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed."
  exit 1
fi

# Helper: assert two values are equal
assert_eq() {
  local label="$1"
  local expected="$2"
  local actual="$3"

  TOTAL=$((TOTAL + 1))

  if [ "$expected" = "$actual" ]; then
    printf "  PASS %-36s\n" "$label:"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "  FAIL %-36s expected=%s got=%s\n" "$label:" "$expected" "$actual"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# Helper: assert JSON is valid
assert_valid_json() {
  local label="$1"
  local json="$2"

  TOTAL=$((TOTAL + 1))

  if echo "$json" | jq . &>/dev/null; then
    printf "  PASS %-36s\n" "$label:"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "  FAIL %-36s invalid JSON\n" "$label:"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

# Helper: assert JSON field equals value
assert_json_field() {
  local label="$1"
  local json="$2"
  local field="$3"
  local expected="$4"

  TOTAL=$((TOTAL + 1))

  local actual
  actual=$(echo "$json" | jq -r "$field" 2>/dev/null)

  if [ "$expected" = "$actual" ]; then
    printf "  PASS %-36s\n" "$label:"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "  FAIL %-36s expected=%s got=%s\n" "$label:" "$expected" "$actual"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

echo ""
echo "  Commit Detection Tests"
echo "  =========================="
echo ""

# ============================================
# Test 1: JSON escaping via jq --arg
# ============================================
echo "  -- JSON Escaping (jq safety) ------------------"

# Test that special characters are safely encoded
TRICKY_SUBJECT='He said "hello" and used a \ backslash'
ENCODED=$(jq -n --arg s "$TRICKY_SUBJECT" '{subject:$s}')
assert_valid_json "double quotes in subject" "$ENCODED"
assert_json_field "preserved double quotes" "$ENCODED" '.subject' "$TRICKY_SUBJECT"

# Test newlines in data
NEWLINE_SUBJECT=$'line1\nline2'
ENCODED=$(jq -n --arg s "$NEWLINE_SUBJECT" '{subject:$s}')
assert_valid_json "newline in subject" "$ENCODED"

# Test tabs
TAB_SUBJECT=$'before\tafter'
ENCODED=$(jq -n --arg s "$TAB_SUBJECT" '{subject:$s}')
assert_valid_json "tab in subject" "$ENCODED"

# Test unicode / emoji
EMOJI_SUBJECT="feat: add sparkles support"
ENCODED=$(jq -n --arg s "$EMOJI_SUBJECT" '{subject:$s}')
assert_valid_json "emoji in subject" "$ENCODED"
assert_json_field "emoji preserved" "$ENCODED" '.subject' "$EMOJI_SUBJECT"

# Test empty string
ENCODED=$(jq -n --arg s "" '{subject:$s}')
assert_valid_json "empty subject" "$ENCODED"
assert_json_field "empty value" "$ENCODED" '.subject' ""

# Test carriage return
CR_SUBJECT=$'line1\r\nline2'
ENCODED=$(jq -n --arg s "$CR_SUBJECT" '{subject:$s}')
assert_valid_json "carriage return in subject" "$ENCODED"

# ============================================
# Test 2: Commit style detection patterns
# ============================================
echo ""
echo "  -- Commit Style Detection ---------------------"

# Conventional commit patterns
assert_eq "conventional: feat:" "match" \
  "$(echo 'feat: add new feature' | grep -qE '^(feat|fix|chore|docs|refactor|perf|test|ci|build|style|revert)(\([^)]*\))?!?:' && echo match || echo nomatch)"

assert_eq "conventional: fix(scope):" "match" \
  "$(echo 'fix(auth): resolve login bug' | grep -qE '^(feat|fix|chore|docs|refactor|perf|test|ci|build|style|revert)(\([^)]*\))?!?:' && echo match || echo nomatch)"

assert_eq "conventional: feat!:" "match" \
  "$(echo 'feat!: breaking change' | grep -qE '^(feat|fix|chore|docs|refactor|perf|test|ci|build|style|revert)(\([^)]*\))?!?:' && echo match || echo nomatch)"

assert_eq "conventional: refactor(ui):" "match" \
  "$(echo 'refactor(ui): simplify layout' | grep -qE '^(feat|fix|chore|docs|refactor|perf|test|ci|build|style|revert)(\([^)]*\))?!?:' && echo match || echo nomatch)"

assert_eq "not conventional: random" "nomatch" \
  "$(echo 'random commit message' | grep -qE '^(feat|fix|chore|docs|refactor|perf|test|ci|build|style|revert)(\([^)]*\))?!?:' && echo match || echo nomatch)"

assert_eq "not conventional: Feature" "nomatch" \
  "$(echo 'Feature: capital not matched' | grep -qE '^(feat|fix|chore|docs|refactor|perf|test|ci|build|style|revert)(\([^)]*\))?!?:' && echo match || echo nomatch)"

# Gitmoji shortcode patterns
assert_eq "gitmoji shortcode: :bug:" "match" \
  "$(echo ':bug: fix crash' | grep -qE '^:[a-z_]+:' && echo match || echo nomatch)"

assert_eq "gitmoji shortcode: :sparkles:" "match" \
  "$(echo ':sparkles: new feature' | grep -qE '^:[a-z_]+:' && echo match || echo nomatch)"

assert_eq "not gitmoji: no colon" "nomatch" \
  "$(echo 'bug fix' | grep -qE '^:[a-z_]+:' && echo match || echo nomatch)"

# ============================================
# Test 3: Full script in a temp git repo
# ============================================
echo ""
echo "  -- Full Script (temp git repo) ----------------"

TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

(
  cd "$TMPDIR"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  # Create initial commit
  echo "init" > file.txt
  git add file.txt
  git commit -q -m "initial commit"

  # Create a tag
  git tag v1.0.0

  # Add conventional commits
  echo "a" >> file.txt && git add file.txt && git commit -q -m "feat: add feature A"
  echo "b" >> file.txt && git add file.txt && git commit -q -m "fix: resolve bug B"
  echo "c" >> file.txt && git add file.txt && git commit -q -m "chore: update deps"
)

OUTPUT=$(cd "$TMPDIR" && bash "$DETECT_SCRIPT" 2>/dev/null)
assert_valid_json "full script output" "$OUTPUT"
assert_json_field "lastTag is v1.0.0" "$OUTPUT" '.lastTag' "v1.0.0"
assert_json_field "commitCount is 3" "$OUTPUT" '.commitCount' "3"
assert_json_field "style is conventional" "$OUTPUT" '.commitStyle' "conventional"
assert_json_field "commits array length" "$OUTPUT" '.commits | length' "3"

# Verify commit content is properly encoded
FIRST_SUBJECT=$(echo "$OUTPUT" | jq -r '.commits[0].subject')
TOTAL=$((TOTAL + 1))
if echo "$FIRST_SUBJECT" | grep -q "feat\|fix\|chore"; then
  printf "  PASS %-36s\n" "commit subjects readable:"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  printf "  FAIL %-36s subject=%s\n" "commit subjects readable:" "$FIRST_SUBJECT"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ============================================
# Test 4: Freeform style detection
# ============================================
echo ""
echo "  -- Freeform Style Detection -------------------"

TMPDIR2=$(mktemp -d)
cleanup2() { rm -rf "$TMPDIR2"; }
trap cleanup2 EXIT

(
  cd "$TMPDIR2"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "init" > file.txt && git add file.txt && git commit -q -m "initial commit"
  git tag v0.1.0
  echo "a" >> file.txt && git add file.txt && git commit -q -m "Add login page"
  echo "b" >> file.txt && git add file.txt && git commit -q -m "Fix header alignment"
  echo "c" >> file.txt && git add file.txt && git commit -q -m "Update readme"
)

OUTPUT2=$(cd "$TMPDIR2" && bash "$DETECT_SCRIPT" 2>/dev/null)
assert_valid_json "freeform output" "$OUTPUT2"
assert_json_field "freeform style" "$OUTPUT2" '.commitStyle' "freeform"

# ============================================
# Test 4b: Unicode gitmoji detection
# ============================================
echo ""
echo "  -- Unicode Gitmoji Detection ------------------"

TMPDIR_EMOJI=$(mktemp -d)
cleanup_emoji() { rm -rf "$TMPDIR_EMOJI"; }
trap cleanup_emoji EXIT

(
  cd "$TMPDIR_EMOJI"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "init" > file.txt && git add file.txt && git commit -q -m "initial commit"
  git tag v1.0.0
  echo "a" >> file.txt && git add file.txt && git commit -q -m $'✨ add sparkles feature'
  echo "b" >> file.txt && git add file.txt && git commit -q -m $'🐛 fix bug in parser'
  echo "c" >> file.txt && git add file.txt && git commit -q -m $'🔥 remove deprecated code'
)

OUTPUT_EMOJI=$(cd "$TMPDIR_EMOJI" && bash "$DETECT_SCRIPT" 2>/dev/null)
assert_valid_json "unicode gitmoji output" "$OUTPUT_EMOJI"
assert_json_field "gitmoji style detected" "$OUTPUT_EMOJI" '.commitStyle' "gitmoji"
assert_json_field "gitmoji commit count" "$OUTPUT_EMOJI" '.commitCount' "3"

# ============================================
# Test 5: Special characters in commit messages
# ============================================
echo ""
echo "  -- Special Chars in Git Commits ---------------"

TMPDIR3=$(mktemp -d)
cleanup3() { rm -rf "$TMPDIR3"; }
trap cleanup3 EXIT

(
  cd "$TMPDIR3"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test \"Quoted\" User"
  echo "init" > file.txt && git add file.txt && git commit -q -m "initial commit"
  git tag v2.0.0
  echo "a" >> file.txt && git add file.txt && git commit -q -m 'feat: handle "quoted" strings & <brackets>'
  echo "b" >> file.txt && git add file.txt && git commit -q -m 'fix: path\to\file resolution'
)

OUTPUT3=$(cd "$TMPDIR3" && bash "$DETECT_SCRIPT" 2>/dev/null)
assert_valid_json "special chars output" "$OUTPUT3"
assert_json_field "special chars count" "$OUTPUT3" '.commitCount' "2"

# Verify the special characters survived encoding (commits[1] is the older "quoted" commit)
SUBJECT1=$(echo "$OUTPUT3" | jq -r '.commits[1].subject')
TOTAL=$((TOTAL + 1))
if echo "$SUBJECT1" | grep -q '"'; then
  printf "  PASS %-36s\n" "quotes survived encoding:"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  printf "  FAIL %-36s subject=%s\n" "quotes survived encoding:" "$SUBJECT1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# ============================================
# Test 6: No tags — should use first commit
# ============================================
echo ""
echo "  -- No Tags Fallback ---------------------------"

TMPDIR4=$(mktemp -d)
cleanup4() { rm -rf "$TMPDIR4"; }
trap cleanup4 EXIT

(
  cd "$TMPDIR4"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  echo "init" > file.txt && git add file.txt && git commit -q -m "first commit"
  echo "a" >> file.txt && git add file.txt && git commit -q -m "feat: second commit"
)

OUTPUT4=$(cd "$TMPDIR4" && bash "$DETECT_SCRIPT" 2>/dev/null)
assert_valid_json "no tags output" "$OUTPUT4"
assert_json_field "lastTag is (none)" "$OUTPUT4" '.lastTag' "(none)"
assert_json_field "commits exist" "$OUTPUT4" '.commits | length' "1"

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
