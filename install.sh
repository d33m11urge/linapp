#!/bin/bash
set -e

BIN="$HOME/.local/bin"
APP="$HOME/.local/share/applications"

echo "Installing linapp..."
mkdir -p "$BIN" "$APP" "$HOME/Applications"

if [ -f "linapp" ]; then
    cp linapp "$BIN/linapp"
elif [ -f ".local/bin/linapp" ]; then
    cp .local/bin/linapp "$BIN/linapp"
else
    echo "Error: linapp source file not found!"
    exit 1
fi

chmod +x "$BIN/linapp"

cat <<EOF > "$APP/linapp-handler.desktop"
[Desktop Entry]
Type=Application
Name=Linapp Installer
Exec=$BIN/linapp %f
MimeType=application/vnd.debian.binary-package;application/gzip;application/x-compressed-tar;application/x-xz;application/x-zstd;application/x-bzip2;
Terminal=false
Icon=system-run
Categories=Utility;System;
EOF

update-desktop-database "$APP"
echo "Done. linapp is ready."
