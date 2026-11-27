#!/usr/bin/env bash
# Regenerate patches/linux-x64.patch from the working tree, including new files, and prove it applies cleanly.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
UPSTREAM="$ROOT/.build/upstream"
PATCH="$ROOT/patches/linux-x64.patch"

[[ -d $UPSTREAM ]] || { echo "no upstream checkout at $UPSTREAM" >&2; exit 1; }

# Intent-to-add makes new files part of the diff; without it a new module silently never reaches CI.
git -C "$UPSTREAM" add -N .
git -C "$UPSTREAM" -c diff.mnemonicPrefix=false diff > "$PATCH"

files=$(grep -c '^diff --git' "$PATCH")
lines=$(wc -l < "$PATCH")
echo "patch: $files files, $lines lines"

# A build mutates the workspace manifests when it upgrades the Office kit; that diff must never ship.
if grep -qE '^diff --git a/(pnpm-lock\.yaml|pnpm-workspace\.yaml)' "$PATCH" ||
   grep -q '"@deepseek-ai/libreoffice-kit": "0\.2\.4"' "$PATCH"; then
  echo "patch: refusing dependency/lockfile hunks — revert them in .build/upstream first" >&2
  exit 1
fi

# A patch that does not apply to the tag is worthless; check against the pristine tree.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git -C "$UPSTREAM" worktree add --detach "$tmp/tree" HEAD >/dev/null 2>&1
if git -C "$tmp/tree" apply --check "$PATCH"; then
  echo "check: applies to $(git -C "$UPSTREAM" describe --tags --exact-match HEAD 2>/dev/null || echo HEAD)"
else
  echo "check: FAILED to apply" >&2
  exit 1
fi
