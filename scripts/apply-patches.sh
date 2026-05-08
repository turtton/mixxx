#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PATCHES_DIR="$ROOT_DIR/patches"
UPSTREAM_DIR="$ROOT_DIR/.upstream"

if [[ ! -d "$UPSTREAM_DIR" ]]; then
  echo "ERROR: .upstream/ not found. Run fetch-upstream.sh first." >&2
  exit 1
fi

if [[ ! -d "$PATCHES_DIR" ]] || [[ -z "$(ls -A "$PATCHES_DIR"/*.patch 2>/dev/null)" ]]; then
  echo "No patches to apply."
  exit 0
fi

DRY_RUN="${1:-}"

cd "$UPSTREAM_DIR"

for patch in "$PATCHES_DIR"/*.patch; do
  patch_name="$(basename "$patch")"
  if [[ "$DRY_RUN" == "--dry-run" ]]; then
    echo "Dry-run: $patch_name"
    if ! git apply --check "$patch" 2>/dev/null; then
      echo "  CONFLICT: $patch_name would not apply cleanly" >&2
      exit 1
    fi
    echo "  OK: $patch_name applies cleanly"
  else
    echo "Applying: $patch_name"
    git apply "$patch"
  fi
done

echo "All patches applied successfully."
