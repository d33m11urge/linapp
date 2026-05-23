#!/bin/bash

# Останавливаем скрипт при любой критической ошибке
set -e

clear
echo "========================================="
echo "       Linapp Deployment Script          "
echo "========================================="
echo ""

# 1. Проверяем наличие папки с исполняемыми файлами в репозитории
if [ ! -d ".local/bin" ]; then
    echo "Error: Directory '.local/bin' not found in the current folder."
    echo "Make sure you ran the script from the cloned repository root."
    exit 1
fi

# 2. Создаем необходимую структуру папок в домашней директории пользователя
INSTALL_DIR="$HOME/.local/bin"
XDG_APPS_DIR="$HOME/.local/share/applications"
APPLICATIONS_FOLDER="$HOME/Applications"

echo "-> Creating directory architecture..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$XDG_APPS_DIR"
mkdir -p "$APPLICATIONS_FOLDER"

# 3. Копируем исполняемые скрипты linapp в систему
echo "-> Deploying core scripts to $INSTALL_DIR..."
cp -r .local/bin/* "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR"/*

# 4. Создаем системный .desktop файл для самого Linapp Installer
echo "-> Generating MIME associations and desktop entries..."
cat << DESKTOP_EOF > "$XDG_APPS_DIR/linapp-installer.desktop"
[Desktop Entry]
Name=Linapp Installer
Exec=$INSTALL_DIR/installer.sh %f
MimeType=application/vnd.debian.binary-package;application/gzip;application/x-compressed-tar;
Terminal=false
Type=Application
Icon=system-software-install
Categories=System;Utility;
Comment=Deploy macOS-style application containers into ~/Applications
DESKTOP_EOF

chmod +x "$XDG_APPS_DIR/linapp-installer.desktop"

# 5. Привязываем форматы файлов .deb и .tar.gz к нашей утилите
echo "-> Binding .deb and .tar.gz mime-types to linapp..."
xdg-mime default linapp-installer.desktop application/vnd.debian.binary-package
xdg-mime default linapp-installer.desktop application/gzip
xdg-mime default linapp-installer.desktop application/x-compressed-tar

# 6. Обновляем кэш приложений, чтобы изменения вступили в силу
echo "-> Refreshing desktop and environment database cache..."
update-desktop-database "$XDG_APPS_DIR"
kbuildsycoca6 &> /dev/null || kbuildsycoca5 &> /dev/null || true

echo ""
echo "========================================="
echo "  Success! linapp automation deployed.  "
echo "  Double-click any .deb or .tar.gz file  "
echo "  to trigger the linapp installer container."
echo "========================================="
