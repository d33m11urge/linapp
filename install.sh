#!/bin/bash
set -e

BIN="$HOME/.local/bin"
APP="$HOME/.local/share/applications"

echo "Installing linapp..."
mkdir -p "$BIN" "$APP" "$HOME/Applications"

cp .local/bin/linapp "$BIN/linapp"
chmod +x "$BIN/linapp"

cat <<EOF > "$APP/linapp-handler.desktop"
[Desktop Entry]
Type=Application
Name=Linapp Installer
Exec=$BIN/linapp %f
MimeType=application/vnd.debian.binary-package;application/gzip;application/x-compressed-tar;
NoDisplay=true
Terminal=false
Icon=package-x-generic
EOF

update-desktop-database "$APP"
echo "Done. linapp is ready."
