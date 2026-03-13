#!/usr/bin/env bash
set -euo pipefail

# changelog-pilot version detection script
# Finds current version across all manifest files

# --- Require jq ---
if ! command -v jq &>/dev/null; then
  echo '{"error":"jq is required but not installed. Install it: https://jqlang.github.io/jq/download/"}' >&2
  exit 1
fi

CURRENT_VERSION=""
VERSION_SOURCE=""

# Accumulate version files as a JSON array
VERSION_FILES="[]"

# --- Helper: add to version files list ---
add_file() {
  local file="$1"
  local version="$2"
  VERSION_FILES=$(echo "$VERSION_FILES" | jq --arg f "$file" --arg v "$version" '. + [{file:$f, version:$v}]')
}

# --- package.json (use jq for safe parsing) ---
if [ -f "package.json" ]; then
  VER=$(jq -r '.version // empty' package.json 2>/dev/null || true)
  if [ -n "$VER" ]; then
    add_file "package.json" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="package.json"
    fi
  fi
fi

# --- package-lock.json (use jq for safe parsing) ---
if [ -f "package-lock.json" ]; then
  VER=$(jq -r '.version // empty' package-lock.json 2>/dev/null || true)
  if [ -n "$VER" ]; then
    add_file "package-lock.json" "$VER"
  fi
fi

# --- pubspec.yaml ---
if [ -f "pubspec.yaml" ]; then
  VER=$(grep -E '^version:' pubspec.yaml 2>/dev/null | head -1 | sed -E 's/^version:[[:space:]]*([0-9][^ ]*).*/\1/')
  if [ -n "$VER" ]; then
    add_file "pubspec.yaml" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="pubspec.yaml"
    fi
  fi
fi

# --- Cargo.toml ---
if [ -f "Cargo.toml" ]; then
  VER=$(grep -E '^version' Cargo.toml 2>/dev/null | head -1 | sed -E 's/^version[[:space:]]*=[[:space:]]*"([^"]*)".*$/\1/')
  if [ -n "$VER" ] && echo "$VER" | grep -qE '^[0-9]+\.[0-9]+'; then
    add_file "Cargo.toml" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="Cargo.toml"
    fi
  fi
fi

# --- pyproject.toml ---
if [ -f "pyproject.toml" ]; then
  VER=$(grep -E '^version' pyproject.toml 2>/dev/null | head -1 | sed -E 's/^version[[:space:]]*=[[:space:]]*"([^"]*)".*$/\1/')
  if [ -n "$VER" ] && echo "$VER" | grep -qE '^[0-9]+\.[0-9]+'; then
    add_file "pyproject.toml" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="pyproject.toml"
    fi
  fi
fi

# --- setup.py ---
if [ -f "setup.py" ]; then
  VER=$(grep -E "version=" setup.py 2>/dev/null | head -1 | sed -E "s/.*version=['\"]([^'\"]*)['\"].*/\1/")
  if [ -n "$VER" ] && echo "$VER" | grep -qE '^[0-9]+\.[0-9]+'; then
    add_file "setup.py" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="setup.py"
    fi
  fi
fi

# --- setup.cfg ---
if [ -f "setup.cfg" ]; then
  VER=$(grep -E '^version' setup.cfg 2>/dev/null | head -1 | sed -E 's/^version[[:space:]]*=[[:space:]]*(.*[^[:space:]])[[:space:]]*/\1/')
  if [ -n "$VER" ] && echo "$VER" | grep -qE '^[0-9]+\.[0-9]+'; then
    add_file "setup.cfg" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="setup.cfg"
    fi
  fi
fi

# --- Python __init__.py with __version__ ---
for init_file in */__init__.py; do
  [ -f "$init_file" ] || continue
  VER=$(grep -E '^__version__' "$init_file" 2>/dev/null | head -1 | sed -E "s/^__version__[[:space:]]*=[[:space:]]*['\"]([^'\"]*)['\"].*/\1/")
  if [ -n "$VER" ]; then
    add_file "$init_file" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="$init_file"
    fi
  fi
done

# --- *.gemspec ---
for gemspec in *.gemspec; do
  [ -f "$gemspec" ] || continue
  VER=$(grep -E '\.version' "$gemspec" 2>/dev/null | head -1 | sed -E "s/.*=[[:space:]]*['\"]([^'\"]*)['\"].*/\1/")
  if [ -n "$VER" ] && echo "$VER" | grep -qE '^[0-9]+\.[0-9]+'; then
    add_file "$gemspec" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="$gemspec"
    fi
  fi
done

# --- version.rb ---
if [ -f "lib/version.rb" ]; then
  VER=$(grep -E 'VERSION' lib/version.rb 2>/dev/null | head -1 | sed -E "s/.*=[[:space:]]*['\"]([^'\"]*)['\"].*/\1/")
  if [ -n "$VER" ]; then
    add_file "lib/version.rb" "$VER"
  fi
fi

# --- *.csproj ---
for csproj in *.csproj; do
  [ -f "$csproj" ] || continue
  VER=$(grep -oE '<Version>[^<]*</Version>' "$csproj" 2>/dev/null | head -1 | sed -E 's/<\/?Version>//g')
  if [ -n "$VER" ]; then
    add_file "$csproj" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="$csproj"
    fi
  fi
done

# --- Directory.Build.props ---
if [ -f "Directory.Build.props" ]; then
  VER=$(grep -oE '<Version>[^<]*</Version>' Directory.Build.props 2>/dev/null | head -1 | sed -E 's/<\/?Version>//g')
  if [ -n "$VER" ]; then
    add_file "Directory.Build.props" "$VER"
  fi
fi

# --- pom.xml (Maven) ---
if [ -f "pom.xml" ]; then
  # Extract the top-level <version> (first occurrence, usually project version)
  VER=$(sed -n '/<parent>/,/<\/parent>/!{ s/.*<version>\([^<]*\)<\/version>.*/\1/p; }' pom.xml 2>/dev/null | head -1)
  if [ -n "$VER" ]; then
    add_file "pom.xml" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="pom.xml"
    fi
  fi
fi

# --- build.gradle / build.gradle.kts ---
for gradle_file in build.gradle build.gradle.kts; do
  [ -f "$gradle_file" ] || continue
  VER=$(grep -E "^version" "$gradle_file" 2>/dev/null | head -1 | sed -E "s/^version[[:space:]]*=?[[:space:]]*['\"]([^'\"]*)['\"].*/\1/")
  if [ -n "$VER" ] && echo "$VER" | grep -qE '^[0-9]+\.[0-9]+'; then
    add_file "$gradle_file" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="$gradle_file"
    fi
  fi
done

# --- Package.swift ---
if [ -f "Package.swift" ]; then
  # Look for a version comment or .library(name:..., version:...) pattern
  VER=$(grep -E 'version:' Package.swift 2>/dev/null | head -1 | sed -E "s/.*version:[[:space:]]*['\"]([^'\"]*)['\"].*/\1/" || true)
  if [ -n "$VER" ] && echo "$VER" | grep -qE '^[0-9]+\.[0-9]+'; then
    add_file "Package.swift" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="Package.swift"
    fi
  fi
fi

# --- Fallback: git tag ---
if [ -z "$CURRENT_VERSION" ]; then
  TAG_VER=$(git tag --sort=-v:refname 2>/dev/null | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//' || true)
  if [ -n "$TAG_VER" ]; then
    CURRENT_VERSION="$TAG_VER"
    VERSION_SOURCE="git-tag"
  fi
fi

# --- Detect version conflicts ---
# Collect unique versions from all version files (excluding lock files)
CONFLICTS="[]"
if [ "$(echo "$VERSION_FILES" | jq 'length')" -gt 1 ]; then
  UNIQUE_VERSIONS=$(echo "$VERSION_FILES" | jq -r '
    [.[] | select(.file | test("lock|Lock") | not)] |
    [.[].version] | unique | length
  ')
  if [ "$UNIQUE_VERSIONS" -gt 1 ]; then
    CONFLICTS=$(echo "$VERSION_FILES" | jq '[.[] | select(.file | test("lock|Lock") | not)]')
  fi
fi

# --- Output (using jq for safe encoding) ---
jq -n \
  --arg version "$CURRENT_VERSION" \
  --arg source "$VERSION_SOURCE" \
  --argjson files "$VERSION_FILES" \
  --argjson conflicts "$CONFLICTS" \
  '{
    currentVersion: $version,
    versionSource: $source,
    allVersionFiles: $files,
    conflicts: $conflicts
  }'
