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

if [[ -n "$PATCH_NAME" ]] && [[ ! "$PATCH_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "ERROR: Patch name must contain only [a-zA-Z0-9._-]" >&2
  exit 1
fi

max_prefix() {
  local max=0
  for f in "$PATCHES_DIR"/*.patch; do
    [[ -f "$f" ]] || continue
    local base num
    base=$(basename "$f")
    num=${base%%[!0-9]*}
    num=${num:-0}
    num=$((10#$num))
    [[ $num -gt $max ]] && max=$num
  done
  echo $max
}

if [[ -z "$PATCH_NAME" ]]; then
  NEXT_NUM=$(printf "%04d" $(($(max_prefix) + 1)))
  echo "Usage: $0 <patch-description>"
  echo "  e.g.: $0 add-opensubsonic-integration"
  echo "  Will create: patches/${NEXT_NUM}-<patch-description>.patch"
  exit 1
fi

cd "$UPSTREAM_DIR"

if git diff --quiet HEAD && git diff --cached --quiet && \
   [[ -z "$(git ls-files --others --exclude-standard)" ]]; then
  echo "ERROR: No changes detected in .upstream/" >&2
  exit 1
fi

NEXT_NUM=$(printf "%04d" $(($(max_prefix) + 1)))
OUTPUT_FILE="$PATCHES_DIR/${NEXT_NUM}-${PATCH_NAME}.patch"
mkdir -p "$PATCHES_DIR"

# Capture current tree (existing patches + user changes)
git add -A
STATE_CURRENT=$(git write-tree)

# Compute baseline tree (pristine HEAD + existing patches only)
git checkout -- . 2>/dev/null
git clean -fd >/dev/null 2>&1

shopt -s nullglob
existing_patches=("$PATCHES_DIR"/*.patch)
shopt -u nullglob

for patch in "${existing_patches[@]}"; do
  git apply "$patch"
done

git add -A
STATE_BASELINE=$(git write-tree)

# Incremental diff: baseline → current = only user's new changes
git diff-tree -p "$STATE_BASELINE" "$STATE_CURRENT" > "$OUTPUT_FILE"

# Restore working tree to current state
git checkout -- . 2>/dev/null
git clean -fd >/dev/null 2>&1
git read-tree "$STATE_CURRENT"
git checkout-index -a -f
git reset HEAD -- . >/dev/null 2>&1

if [[ ! -s "$OUTPUT_FILE" ]]; then
  rm -f "$OUTPUT_FILE"
  echo "ERROR: No incremental changes detected (changes may already be in existing patches)" >&2
  exit 1
fi

echo "Patch created: $OUTPUT_FILE"
