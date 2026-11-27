#!/usr/bin/env bash
# Static checks on patches/linux-x64.patch that catch the failure classes seen in practice.
# Cheap enough for a CI preflight; the deep apply check lives in build.sh, which has the checkout.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PATCH="$ROOT/patches/linux-x64.patch"
fail=0
check() {
  local name=$1; shift
  if "$@"; then echo "ok   $name"; else echo "FAIL $name" >&2; fail=1; fi
}
absent() { ! grep -qE "$1" "$PATCH"; }

[[ -s $PATCH ]] || { echo "FAIL patch exists and is non-empty" >&2; exit 1; }
echo "info $(grep -c '^diff --git' "$PATCH") files, $(wc -l < "$PATCH") lines"

# A build that upgrades a dependency must not leak that into the patch: it invalidates on the next tag.
check "no lockfile hunks" absent '^diff --git a/(pnpm-lock\.yaml|pnpm-workspace\.yaml)'
check "no dependency bumps" absent '"@deepseek-ai/libreoffice-kit": "0\.2\.4"'
# Credentials must never reach a repository that publishes releases.
check "no secrets" absent 'sk-[A-Za-z0-9]{16,}|gh[pousr]_[A-Za-z0-9]{20,}|BEGIN [A-Z ]*PRIVATE KEY|Authorization: [[:alnum:]]'
# Machine-specific paths make the patch unusable everywhere else.
check "no home paths" absent '^\+.*/home/[a-z0-9_.-]+/'
check "no binary hunks" absent 'GIT binary patch'

# Deep check when a checkout is available locally; CI relies on build.sh for this.
if [[ -d $ROOT/.build/upstream ]]; then
  check "applies to checkout" git -C "$ROOT/.build/upstream" apply --check --reverse "$PATCH"
fi

[[ $fail -eq 0 ]] || { echo "preflight failed" >&2; exit 1; }
