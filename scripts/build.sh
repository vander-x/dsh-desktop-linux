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

mkdir -p "$ROOT/dist" "$ROOT/.build/tmp"
# /tmp is a small tmpfs on many systems; keep build scratch on disk instead.
export TMPDIR="$ROOT/.build/tmp"
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
# CI=true keeps lefthook's postinstall from rewriting the user's global core.hooksdir.
CI=true pnpm install --frozen-lockfile

# Native Office engine: upstream pins kit 0.2.3, the first release with Linux prebuilts is 0.2.4.
# Only that known version is upgraded, so a newer upstream pin is never downgraded.
KIT_VERSION=$(pnpm --filter @deepseek-ai/dsh-office-kit exec node -p "require('@deepseek-ai/libreoffice-kit/package.json').version" 2>/dev/null || true)
if [[ $KIT_VERSION == "0.2.3" ]]; then
  echo "office: kit 0.2.3 has no Linux engine, upgrading to 0.2.4"
  pnpm --filter @deepseek-ai/dsh-office-kit --filter @deepseek-ai/dsh-web-app add @deepseek-ai/libreoffice-kit@0.2.4
fi

pnpm --filter @deepseek-ai/dsh-desktop run package:linux:x64 -- --unsigned

cp apps/desktop/.desktop-build/targets/linux-x64/unsigned-artifacts/*.AppImage "$ROOT/dist/"
ls -lh "$ROOT/dist"
