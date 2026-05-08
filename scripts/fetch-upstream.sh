#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="$ROOT_DIR/.upstream-version"
UPSTREAM_DIR="$ROOT_DIR/.upstream"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "ERROR: .upstream-version not found" >&2
  exit 1
fi

VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"
REPO_URL="https://github.com/mixxxdj/mixxx.git"

echo "Fetching upstream mixxx version: $VERSION"

if [[ -d "$UPSTREAM_DIR/.git" ]]; then
  echo "Upstream directory exists, checking out tag..."
  cd "$UPSTREAM_DIR"
  git fetch --tags --depth=1 origin "refs/tags/$VERSION:refs/tags/$VERSION" 2>/dev/null || \
    git fetch --tags origin
  git checkout "$VERSION" -- . 2>/dev/null || git checkout "tags/$VERSION"
else
  echo "Cloning upstream at tag $VERSION..."
  rm -rf "$UPSTREAM_DIR"
  git clone --depth=1 --branch "$VERSION" "$REPO_URL" "$UPSTREAM_DIR"
fi

echo "Upstream source ready at: $UPSTREAM_DIR (version: $VERSION)"
