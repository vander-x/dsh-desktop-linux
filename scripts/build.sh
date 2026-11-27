#!/usr/bin/env bash
# Build the DeepSeek Harness desktop AppImage for Linux from the upstream release npm "latest" points to.
# Usage: scripts/build.sh [tag]   (tag like dsh-v0.2.2-rc.5; default resolves npm latest)
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
UPSTREAM=https://github.com/deepseek-ai/deepseek-harness.git

VERSION=${1:-}
if [[ -z $VERSION ]]; then
  VERSION="dsh-v$(npm view @deepseek-ai/dsh@latest version)"
fi

mkdir -p "$ROOT/dist"
CURRENT=$(git -C "$ROOT/.build/upstream" describe --tags 2>/dev/null || true)
if [[ $CURRENT != "$VERSION" ]]; then
  rm -rf "$ROOT/.build/upstream"
  git clone --depth 1 --branch "$VERSION" "$UPSTREAM" "$ROOT/.build/upstream"
fi
# Apply once; a checkout that already carries the patch is reused instead of failing.
if git -C "$ROOT/.build/upstream" apply --check "$ROOT/patches/linux-x64.patch" 2>/dev/null; then
  git -C "$ROOT/.build/upstream" apply "$ROOT/patches/linux-x64.patch"
elif git -C "$ROOT/.build/upstream" apply --reverse --check "$ROOT/patches/linux-x64.patch" 2>/dev/null; then
  echo "patch já aplicado, reutilizando checkout"
else
  echo "checkout inconsistente: apague .build/upstream e rode de novo" >&2
  exit 1
fi

cd "$ROOT/.build/upstream"
# The host typecheck needs more heap than Node's default, and gate parallelism drives peak memory.
export NODE_OPTIONS=--max-old-space-size=6144
export DSH_GATE_CONCURRENCY=${DSH_GATE_CONCURRENCY:-2}
# CI=true keeps lefthook's postinstall from rewriting the user's global core.hooksPath.
CI=true pnpm install --frozen-lockfile
pnpm --filter @deepseek-ai/dsh-desktop run package:linux:x64 -- --unsigned

cp apps/desktop/.desktop-build/targets/linux-x64/unsigned-artifacts/*.AppImage "$ROOT/dist/"
ls -lh "$ROOT/dist"
