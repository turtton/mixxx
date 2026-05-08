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

shopt -s nullglob
patches=("$PATCHES_DIR"/*.patch)
shopt -u nullglob

if [[ ${#patches[@]} -eq 0 ]]; then
  echo "No patches to apply."
  exit 0
fi

DRY_RUN="${1:-}"
cd "$UPSTREAM_DIR"

if [[ "$DRY_RUN" == "--dry-run" ]]; then
  # Sequential dry-run: apply each patch so next is checked against applied state
  applied=()
  for patch in "${patches[@]}"; do
    patch_name="$(basename "$patch")"
    echo "Dry-run: $patch_name"
    if ! git apply --check "$patch" 2>/dev/null; then
      echo "  CONFLICT: $patch_name would not apply cleanly" >&2
      # Undo previously applied patches in reverse order
      for ((i=${#applied[@]}-1; i>=0; i--)); do
        git apply --reverse "${applied[$i]}" 2>/dev/null
      done
      exit 1
    fi
    echo "  OK: $patch_name applies cleanly"
    git apply "$patch"
    applied+=("$patch")
  done
  # Undo all patches (dry-run only validates)
  for ((i=${#applied[@]}-1; i>=0; i--)); do
    git apply --reverse "${applied[$i]}" 2>/dev/null
  done
else
  # Sequential apply with inline check
  for patch in "${patches[@]}"; do
    patch_name="$(basename "$patch")"
    echo "Applying: $patch_name"
    if ! git apply "$patch"; then
      echo "FAILED: $patch_name" >&2
      exit 1
    fi
  done
fi

echo "All patches applied successfully."
