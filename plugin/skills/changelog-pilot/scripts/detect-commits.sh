#!/usr/bin/env bash
set -euo pipefail

# changelog-pilot commit detection script
# Finds last tag, lists commits since, detects commit style

# --- Require jq ---
if ! command -v jq &>/dev/null; then
  echo '{"error":"jq is required but not installed. Install it: https://jqlang.github.io/jq/download/"}' >&2
  exit 1
fi

LAST_TAG=""
COMMIT_COUNT=0
COMMIT_STYLE="freeform"

# --- Find last semver tag ---
LAST_TAG=$(git tag --sort=-v:refname 2>/dev/null | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)

if [ -z "$LAST_TAG" ]; then
  # No tags found — use first commit
  FIRST_COMMIT=$(git rev-list --max-parents=0 HEAD 2>/dev/null | head -1 || true)
  if [ -z "$FIRST_COMMIT" ]; then
    echo '{"lastTag":"","commitCount":0,"commitStyle":"freeform","commits":[]}'
    exit 0
  fi
  RANGE="$FIRST_COMMIT..HEAD"
  LAST_TAG="(none)"
else
  RANGE="$LAST_TAG..HEAD"
fi

# --- Count commits ---
COMMIT_COUNT=$(git rev-list --count "$RANGE" 2>/dev/null || echo "0")

if [ "$COMMIT_COUNT" -eq 0 ]; then
  jq -n --arg tag "$LAST_TAG" '{lastTag:$tag,commitCount:0,commitStyle:"freeform",commits:[]}'
  exit 0
fi

# --- Detect commit style from first 10 commits ---
SAMPLE=$(git log "$RANGE" --format="%s" --max-count=10 2>/dev/null)

CONVENTIONAL_COUNT=0
GITMOJI_COUNT=0
TOTAL_SAMPLE=0

while IFS= read -r msg; do
  [ -z "$msg" ] && continue
  TOTAL_SAMPLE=$((TOTAL_SAMPLE + 1))

  # Check for Conventional Commits pattern: type(scope): description or type: description
  if echo "$msg" | grep -qE '^(feat|fix|chore|docs|refactor|perf|test|ci|build|style|revert)(\([^)]*\))?!?:'; then
    CONVENTIONAL_COUNT=$((CONVENTIONAL_COUNT + 1))
  fi

  # Check for Gitmoji pattern: starts with an emoji (portable — no grep -P)
  # Detect common gitmoji Unicode byte patterns and :shortcode: syntax
  if echo "$msg" | perl -ne 'exit 0 if /^[\x{2600}-\x{27BF}\x{1F300}-\x{1FBFF}\x{FE00}-\x{FE0F}\x{200D}\x{E0020}-\x{E007F}]/; exit 1' 2>/dev/null \
     || echo "$msg" | grep -qE '^:[a-z_]+:' 2>/dev/null; then
    GITMOJI_COUNT=$((GITMOJI_COUNT + 1))
  fi
done <<< "$SAMPLE"

if [ "$TOTAL_SAMPLE" -gt 0 ]; then
  CONV_PCT=$((CONVENTIONAL_COUNT * 100 / TOTAL_SAMPLE))
  GITMOJI_PCT=$((GITMOJI_COUNT * 100 / TOTAL_SAMPLE))

  if [ "$CONV_PCT" -ge 60 ]; then
    COMMIT_STYLE="conventional"
  elif [ "$GITMOJI_PCT" -ge 60 ]; then
    COMMIT_STYLE="gitmoji"
  else
    COMMIT_STYLE="freeform"
  fi
fi

# --- List commits as JSON array (using jq for safe encoding) ---
COMMITS_JSON="[]"

while IFS='|' read -r hash subject author email date; do
  [ -z "$hash" ] && continue

  COMMITS_JSON=$(echo "$COMMITS_JSON" | jq \
    --arg h "$hash" \
    --arg s "$subject" \
    --arg a "$author" \
    --arg e "$email" \
    --arg d "$date" \
    '. + [{hash:$h, subject:$s, author:$a, email:$e, date:$d}]')
done < <(git log "$RANGE" --format="%H|%s|%an|%ae|%aI" 2>/dev/null)

# --- Output (using jq for safe encoding) ---
jq -n \
  --arg tag "$LAST_TAG" \
  --argjson count "$COMMIT_COUNT" \
  --arg style "$COMMIT_STYLE" \
  --argjson commits "$COMMITS_JSON" \
  '{lastTag:$tag, commitCount:$count, commitStyle:$style, commits:$commits}'
