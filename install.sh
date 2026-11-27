#!/usr/bin/env bash
# Install the newest AppImage published by this repository.
set -euo pipefail

REPO=${DSH_DESKTOP_REPO:-vander-x/dsh-desktop-linux}
DEST="$HOME/.local/opt/dsh-desktop"
URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
  grep -oE 'https://[^"]+\.AppImage' | head -1)

[[ -n $URL ]] || { echo "no AppImage in the latest release of $REPO" >&2; exit 1; }

mkdir -p "$DEST" "$HOME/.local/bin" "$HOME/.local/share/applications"
# Write beside the target and rename: a running AppImage keeps its FUSE mount on the old inode.
curl -fsSL "$URL" -o "$DEST/dsh.AppImage.new"
chmod +x "$DEST/dsh.AppImage.new"
mv -f "$DEST/dsh.AppImage.new" "$DEST/dsh.AppImage"

# An AppImage cannot keep the SUID bit on chrome-sandbox, so the launcher disables the sandbox.
rm -f "$HOME/.local/bin/dsh-desktop"
cat > "$HOME/.local/bin/dsh-desktop" <<EOF
#!/usr/bin/env bash
exec "$DEST/dsh.AppImage" --no-sandbox "\$@"
EOF
chmod +x "$HOME/.local/bin/dsh-desktop"

cat > "$HOME/.local/share/applications/dsh-desktop.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DeepSeek Harness
Comment=DeepSeek Harness desktop (unofficial Linux build)
Exec=$HOME/.local/bin/dsh-desktop %U
Terminal=false
Categories=Development;
StartupWMClass=deepseek-ai-dsh-desktop
EOF

echo "installed: $DEST/dsh.AppImage ($(basename "$URL"))"

# The AppImage carries the 1024px product icon; without installing it the desktop entry shows a blank icon.
ICON_TMP=$(mktemp -d)
trap 'rm -rf "$ICON_TMP"' EXIT
(cd "$ICON_TMP" && "$DEST/dsh.AppImage" --appimage-extract 'usr/share/icons/hicolor/1024x1024/apps/deepseek-harness.png' >/dev/null 2>&1 || true)
if [[ -f $ICON_TMP/squashfs-root/usr/share/icons/hicolor/1024x1024/apps/deepseek-harness.png ]]; then
  install -Dm644 "$ICON_TMP/squashfs-root/usr/share/icons/hicolor/1024x1024/apps/deepseek-harness.png" \
    "$HOME/.local/share/icons/hicolor/1024x1024/apps/deepseek-harness.png"
  echo "icon: installed"
else
  echo "icon: not found inside the AppImage" >&2
fi
