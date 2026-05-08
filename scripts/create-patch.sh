#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PATCHES_DIR="$ROOT_DIR/patches"
UPSTREAM_DIR="$ROOT_DIR/.upstream"

if [[ ! -d "$UPSTREAM_DIR/.git" ]]; then
  echo "ERROR: .upstream/ is not a git repo. Run fetch-upstream.sh first." >&2
  exit 1
fi

PATCH_NAME="${1:-}"
if [[ -z "$PATCH_NAME" ]]; then
  EXISTING=$(ls "$PATCHES_DIR"/*.patch 2>/dev/null | wc -l)
  NEXT_NUM=$(printf "%04d" $((EXISTING + 1)))
  echo "Usage: $0 <patch-description>"
  echo "  e.g.: $0 add-opensubsonic-integration"
  echo "  Will create: patches/${NEXT_NUM}-<patch-description>.patch"
  exit 1
fi

cd "$UPSTREAM_DIR"

if git diff --quiet && git diff --cached --quiet; then
  echo "ERROR: No changes detected in .upstream/" >&2
  exit 1
fi

EXISTING=$(ls "$PATCHES_DIR"/*.patch 2>/dev/null | wc -l)
NEXT_NUM=$(printf "%04d" $((EXISTING + 1)))
OUTPUT_FILE="$PATCHES_DIR/${NEXT_NUM}-${PATCH_NAME}.patch"

mkdir -p "$PATCHES_DIR"

git diff > "$OUTPUT_FILE"

if [[ -s "$OUTPUT_FILE" ]]; then
  echo "Patch created: $OUTPUT_FILE"
else
  git diff --cached > "$OUTPUT_FILE"
  if [[ -s "$OUTPUT_FILE" ]]; then
    echo "Patch created (from staged): $OUTPUT_FILE"
  else
    rm -f "$OUTPUT_FILE"
    echo "ERROR: No diff output generated" >&2
    exit 1
  fi
fi
