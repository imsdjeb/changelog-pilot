#!/usr/bin/env bash
set -euo pipefail

# changelog-pilot version detection script
# Finds current version across all manifest files

CURRENT_VERSION=""
VERSION_SOURCE=""
ALL_VERSION_FILES="[]"

FILES_FOUND=""

# --- Helper: add to files list ---
add_file() {
  local file="$1"
  local version="$2"
  if [ -n "$FILES_FOUND" ]; then
    FILES_FOUND="$FILES_FOUND,"
  fi
  FILES_FOUND="$FILES_FOUND{\"file\":\"$file\",\"version\":\"$version\"}"
}

# --- package.json ---
if [ -f "package.json" ]; then
  VER=$(grep '"version"' package.json 2>/dev/null | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*$/\1/')
  if [ -n "$VER" ]; then
    add_file "package.json" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="package.json"
    fi
  fi
fi

# --- package-lock.json (root version) ---
if [ -f "package-lock.json" ]; then
  VER=$(grep -m1 '"version"' package-lock.json 2>/dev/null | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]*)".*$/\1/')
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
  if [ -n "$VER" ]; then
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
  if [ -n "$VER" ]; then
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
  if [ -n "$VER" ]; then
    add_file "setup.py" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="setup.py"
    fi
  fi
fi

# --- setup.cfg ---
if [ -f "setup.cfg" ]; then
  VER=$(grep -E '^version' setup.cfg 2>/dev/null | head -1 | sed -E 's/^version[[:space:]]*=[[:space:]]*(.*)/\1/')
  if [ -n "$VER" ]; then
    add_file "setup.cfg" "$VER"
    if [ -z "$CURRENT_VERSION" ]; then
      CURRENT_VERSION="$VER"
      VERSION_SOURCE="setup.cfg"
    fi
  fi
fi

# --- *.gemspec ---
for gemspec in *.gemspec; do
  [ -f "$gemspec" ] || continue
  VER=$(grep -E '\.version' "$gemspec" 2>/dev/null | head -1 | sed -E "s/.*=[[:space:]]*['\"]([^'\"]*)['\"].*/\1/")
  if [ -n "$VER" ]; then
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

# --- Fallback: git tag ---
if [ -z "$CURRENT_VERSION" ]; then
  TAG_VER=$(git tag --sort=-v:refname 2>/dev/null | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//')
  if [ -n "$TAG_VER" ]; then
    CURRENT_VERSION="$TAG_VER"
    VERSION_SOURCE="git-tag"
  fi
fi

# --- Output ---
cat <<EOF
{
  "currentVersion": "$CURRENT_VERSION",
  "versionSource": "$VERSION_SOURCE",
  "allVersionFiles": [$FILES_FOUND]
}
EOF
