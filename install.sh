#!/usr/bin/env bash
# Noxtis installer for Linux (x86_64).
#
#   curl -fsSL https://raw.githubusercontent.com/NotPandaByte/noxtis/main/install.sh | bash
#
# Downloads the latest AppImage from GitHub releases into ~/.local/share/noxtis,
# links it as ~/.local/bin/noxtis, and adds a desktop entry. Re-run to update
# (the app also updates itself from Settings once installed).
set -euo pipefail

REPO="NotPandaByte/noxtis"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
APP_DIR="$DATA_DIR/noxtis"
BIN_DIR="$HOME/.local/bin"
APP="$APP_DIR/noxtis.AppImage"

say() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
err() { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Linux" ] || err "This installer is Linux-only — downloads for other platforms: https://github.com/$REPO/releases/latest"
[ "$(uname -m)" = "x86_64" ] || err "Only x86_64 builds are published right now (this machine is $(uname -m))."
command -v curl >/dev/null 2>&1 || err "curl is required."

say "Finding the latest release…"
api="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")" ||
  err "Couldn't reach the GitHub API."
url="$(printf '%s' "$api" | grep -o '"browser_download_url": *"[^"]*_amd64\.AppImage"' | head -1 | cut -d'"' -f4)"
[ -n "$url" ] || err "No AppImage found in the latest release."
version="$(printf '%s' "$api" | grep -o '"tag_name": *"[^"]*"' | head -1 | cut -d'"' -f4)"

say "Downloading Noxtis $version…"
mkdir -p "$APP_DIR" "$BIN_DIR"
curl -fL --progress-bar -o "$APP.tmp" "$url"
chmod +x "$APP.tmp"
mv "$APP.tmp" "$APP"
ln -sf "$APP" "$BIN_DIR/noxtis"

# AppImages mount themselves with libfuse2, which some distros don't preinstall.
if ! ldconfig -p 2>/dev/null | grep -q 'libfuse\.so\.2'; then
  if command -v pacman >/dev/null 2>&1; then
    say "One more thing — AppImages need fuse2:  sudo pacman -S fuse2"
  elif command -v apt-get >/dev/null 2>&1; then
    say "One more thing — AppImages need libfuse2:  sudo apt install libfuse2"
  else
    say "One more thing — install libfuse2 with your package manager (AppImages need it)."
  fi
fi

# Desktop entry + icon so it shows up in app launchers.
icon_dir="$DATA_DIR/icons/hicolor/128x128/apps"
mkdir -p "$icon_dir" "$DATA_DIR/applications"
curl -fsSL -o "$icon_dir/noxtis.png" \
  "https://raw.githubusercontent.com/$REPO/main/editor/src-tauri/icons/128x128.png" || true
cat > "$DATA_DIR/applications/noxtis.desktop" <<EOF
[Desktop Entry]
Name=Noxtis
Comment=Code editor
Exec=$APP
Icon=noxtis
Type=Application
Categories=Development;IDE;
EOF
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DATA_DIR/applications" 2>/dev/null || true
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) say "Note: $BIN_DIR isn't on your PATH — add it to run 'noxtis' from a terminal." ;;
esac

say "Done! Launch Noxtis from your app menu or run: noxtis"
say "It keeps itself up to date from Settings → Check for updates."
