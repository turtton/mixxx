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

VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
REPO_URL="https://github.com/mixxxdj/mixxx.git"

echo "Fetching upstream mixxx version: $VERSION"

# Always start from a clean state to avoid stale files from previous patches
if [[ -d "$UPSTREAM_DIR" ]]; then
  echo "Removing existing upstream directory..."
  rm -rf "$UPSTREAM_DIR"
fi

echo "Cloning upstream at tag $VERSION..."
git clone --depth=1 --branch "$VERSION" "$REPO_URL" "$UPSTREAM_DIR"

echo "Upstream source ready at: $UPSTREAM_DIR (version: $VERSION)"
