#!/bin/bash

set -e

clear
echo "========================================="
echo "       Linapp System Installer           "
echo "========================================="
echo ""

if [ ! -d ".local/bin" ]; then
    echo "Error: Directory '.local/bin' not found."
    echo "Please run this script from the root of the cloned repository."
    exit 1
fi

BIN_DIR="$HOME/.local/bin"
XDG_APPS_DIR="$HOME/.local/share/applications"
APPS_DIR="$HOME/Applications"

echo "-> Creating local environment folders..."
mkdir -p "$BIN_DIR"
mkdir -p "$XDG_APPS_DIR"
mkdir -p "$APPS_DIR"

echo "-> Deploying core executable scripts..."
cp -r .local/bin/* "$BIN_DIR/"
chmod +x "$BIN_DIR"/*

echo "-> Generating desktop MIME entry..."
cat << DESKTOP_EOF > "$XDG_APPS_DIR/linapp-installer.desktop"
[Desktop Entry]
Name=Linapp Installer
# ИСПРАВЛЕНО: Теперь ссылается на твой файл 'linapp' вместо 'installer.sh'
Exec=$BIN_DIR/linapp %f
MimeType=application/vnd.debian.binary-package;application/gzip;application/x-compressed-tar;application/x-xz;
Terminal=false
Type=Application
Icon=system-software-install
Categories=System;Utility;
Comment=Deploy applications to ~/Applications
DESKTOP_EOF

chmod +x "$XDG_APPS_DIR/linapp-installer.desktop"

echo "-> Registering file associations..."
xdg-mime default linapp-installer.desktop application/vnd.debian.binary-package
xdg-mime default linapp-installer.desktop application/gzip
xdg-mime default linapp-installer.desktop application/x-compressed-tar
# ДОБАВЛЕНО: Поддержка формата .xz на уровне ассоциаций
xdg-mime default linapp-installer.desktop application/x-xz

echo "-> Rebuilding desktop database cache..."
update-desktop-database "$XDG_APPS_DIR"
kbuildsycoca6 &> /dev/null || kbuildsycoca5 &> /dev/null || true

echo ""
echo "========================================="
echo "  Linapp has been successfully installed! "
echo "  You can now double-click any package.  "
echo "========================================="
