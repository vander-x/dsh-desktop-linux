#!/usr/bin/env bash
# Verify a built AppImage without a model key: boot the Host and read its configuration.
# Usage: scripts/verify-appimage.sh dist/DeepSeek-Harness-*.AppImage
set -euo pipefail

IMAGE=${1:?pass the AppImage path}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

cd "$WORK"
"$IMAGE" --appimage-extract >/dev/null 2>&1
APPDIR=$WORK/squashfs-root

# The bundled CLI runs the same runtime the desktop Host uses.
"$APPDIR/resources/runtime/cli/bin/dsh" --profile web --dump-config > "$WORK/dump.yml"
grep -q 'dsh-base' "$WORK/dump.yml"
echo "cli: dump-config ok ($(wc -l < "$WORK/dump.yml") linhas)"

# Boot the window briefly and fail on the startup errors this port had to fix.
if [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]]; then
  set +e
  timeout 25 "$APPDIR/deepseek-harness" --no-sandbox > "$WORK/boot.log" 2>&1
  set -e
  if grep -qE 'desktop policy: unsupported platform|SIGSEGV|Cannot find module' "$WORK/boot.log"; then
    echo "boot: FALHOU" >&2
    tail -20 "$WORK/boot.log" >&2
    exit 1
  fi
  echo "boot: janela abriu sem erro fatal"
else
  echo "boot: sem display, pulado"
fi
