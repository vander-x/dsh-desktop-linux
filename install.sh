#!/usr/bin/env bash
# Install the newest AppImage published by this repo.
set -euo pipefail

REPO=${DSH_DESKTOP_REPO:?set DSH_DESKTOP_REPO=owner/repo}
DEST="$HOME/.local/opt/dsh-desktop"
URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
  grep -oE 'https://[^"]+\.AppImage' | head -1)

[[ -n $URL ]] || { echo "nenhum AppImage no último release de $REPO" >&2; exit 1; }

mkdir -p "$DEST" "$HOME/.local/bin" "$HOME/.local/share/applications"
curl -fsSL "$URL" -o "$DEST/dsh-desktop.AppImage"
chmod +x "$DEST/dsh-desktop.AppImage"
ln -sf "$DEST/dsh-desktop.AppImage" "$HOME/.local/bin/dsh-desktop"

cat > "$HOME/.local/share/applications/dsh-desktop.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DeepSeek Harness
Comment=DeepSeek Harness desktop (unofficial Linux build)
Exec=$HOME/.local/bin/dsh-desktop %U
Terminal=false
Categories=Development;
EOF

echo "instalado: $DEST/dsh-desktop.AppImage (versão $(basename "$URL"))"
