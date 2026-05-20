#!/bin/bash

set -euo pipefail

INSTALL_DIR="$HOME/.local/bin"
TARGET_SCRIPT="$INSTALL_DIR/linapp"
APPLICATIONS_DIR="$HOME/Applications"

mkdir -p "$INSTALL_DIR" "$APPLICATIONS_DIR"

cat << 'EOF' > "$TARGET_SCRIPT"
#!/bin/bash

set -e

if [ -z "$1" ]; then
    notify-send "linapp" "Error: No input file specified." --icon=error
    exit 1
fi

FILE="$(realpath "$1")"
EXT="${FILE##*.}"
FILENAME=$(basename "$FILE")
APP_NAME=$(echo "$FILENAME" | cut -d'-' -f1 | cut -d'_' -f1 | tr '[:upper:]' '[:lower:]')

TMP_BUILD="/tmp/linapp_build_${APP_NAME}"
FINAL_APPS_DIR="$HOME/Applications"
DMG_VOLUME="/tmp/${APP_NAME}-Installer"

rm -rf "$TMP_BUILD" "$DMG_VOLUME"
mkdir -p "$TMP_BUILD" "$FINAL_APPS_DIR" "$DMG_VOLUME"
cd "$TMP_BUILD"

notify-send "linapp" "Processing ${APP_NAME}..." --icon=package-x-generic

if [ "$EXT" = "deb" ]; then
    bsdtar -xf "$FILE" 2>/dev/null
    if [ -f data.tar* ]; then 
        tar -xf data.tar* && rm -f data.tar*
    fi
else
    mkdir -p tmp_extract
    bsdtar -xf "$FILE" -C tmp_extract/ 2>/dev/null || tar -xf "$FILE" -C tmp_extract/
    mv tmp_extract/*/* . 2>/dev/null || mv tmp_extract/* . 2>/dev/null
    rm -rf tmp_extract
fi

find . -depth -name "* *" -execdir bash -c 'mv "$1" "${1// /_}"' _ {} \; 2>/dev/null || true

DESKTOP_FILE=$(find . -name "*.desktop" | grep -v "url_handler" | head -n 1 || true)
BIN_FILE=""
LAUNCH_CMD=""

if [ -f "$DESKTOP_FILE" ]; then
    BIN_NAME=$(grep -E "^Exec=" "$DESKTOP_FILE" | head -n 1 | cut -d= -f2- | cut -d' ' -f1 | sed 's/"//g' | xargs basename || true)
    BIN_FILE=$(find ./usr/bin ./opt ./bin ./usr/share -type f -executable -name "$BIN_NAME" 2>/dev/null | head -n 1 || true)
fi

if [ -z "$BIN_FILE" ]; then
    BIN_FILE=$(find . -type f -name "*.jar" | head -n 1 || true)
    if [ -n "$BIN_FILE" ]; then
        LAUNCH_CMD="java -jar "
    fi
fi

if [ -z "$BIN_FILE" ]; then
    BIN_FILE=$(find . -type f -executable 2>/dev/null | grep -v -E "bootstrap|crashpad|sandbox|AppRun|\.desktop|\.sh|\.png|\.svg|\.txt" | head -n 1 || true)
fi

if [ -z "$BIN_FILE" ]; then
    notify-send "linapp" "Error: Executable target not found." --icon=error
    exit 1
fi

BIN_FILE_CLEAN=$(echo "$BIN_FILE" | sed 's|^\./||')
BIN_DIR=$(dirname "$BIN_FILE_CLEAN")

cat <<EOF > "$TMP_BUILD/AppRun"
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\$0")")"

if [ "$BIN_DIR" = "." ]; then
    export LD_LIBRARY_PATH="\$HERE:\$HERE/usr/lib:\$HERE/usr/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH"
else
    export LD_LIBRARY_PATH="\$HERE/$BIN_DIR:\$HERE/usr/lib:\$HERE/usr/lib/x86_64-linux-gnu:\$LD_LIBRARY_PATH"
fi
export XDG_DATA_DIRS="\$HERE/usr/share:\$XDG_DATA_DIRS"

exec ${LAUNCH_CMD}"\$HERE/$BIN_FILE_CLEAN" "\$@"
EOF

chmod +x "$TMP_BUILD/AppRun"

LAUNCHER_DIR="$HOME/.local/share/applications"
mkdir -p "$LAUNCHER_DIR"

if [ -f "$DESKTOP_FILE" ]; then
    LOCAL_DESKTOP="$TMP_BUILD/${APP_NAME}.desktop"
    if [ "$(realpath "$DESKTOP_FILE")" != "$(realpath "$LOCAL_DESKTOP")" ]; then
        cp "$DESKTOP_FILE" "$LOCAL_DESKTOP"
    fi
    
    if [ -n "$LAUNCH_CMD" ]; then
        sed -i "s@^Exec=.*@Exec=$FINAL_APPS_DIR/$APP_NAME/AppRun@" "$LOCAL_DESKTOP"
    else
        sed -i "s@^Exec=.*@Exec=$FINAL_APPS_DIR/$APP_NAME/AppRun %U@" "$LOCAL_DESKTOP"
    fi
    
    sed -i '/^Path=/d' "$LOCAL_DESKTOP"
    echo "Path=$FINAL_APPS_DIR/$APP_NAME" >> "$LOCAL_DESKTOP"
    
    if grep -q "^Terminal=" "$LOCAL_DESKTOP"; then
        sed -i "s@^Terminal=.*@Terminal=false@" "$LOCAL_DESKTOP"
    else
        echo "Terminal=false" >> "$LOCAL_DESKTOP"
    fi
    
    ICON_PATH=$(find . -name "${APP_NAME}.png" -o -name "google-chrome.png" -o -name "discord.png" -o -name "icon.png" -o -name "*.png" | head -n 1 || true)
    if [ -n "$ICON_PATH" ]; then
        CLEAN_ICON_PATH=$(echo "$ICON_PATH" | sed 's|^\./||')
        sed -i "s@^Icon=.*@Icon=$FINAL_APPS_DIR/$APP_NAME/$CLEAN_ICON_PATH@" "$LOCAL_DESKTOP"
    fi
    ln -sf "$FINAL_APPS_DIR/$APP_NAME/${APP_NAME}.desktop" "$LAUNCHER_DIR/${APP_NAME}.desktop"
fi

EJECT_SCRIPT="$DMG_VOLUME/Eject_Installer.sh"
cat <<EOF > "$EJECT_SCRIPT"
#!/bin/bash
pkill -f "dolphin $DMG_VOLUME" || true
rm -rf "$DMG_VOLUME"
update-desktop-database "\$HOME/.local/share/applications" 2>/dev/null || true
kbuildsycoca6 2>/dev/null || kbuildsycoca5 2>/dev/null || true
EOF
chmod +x "$EJECT_SCRIPT"

mkdir -p "$DMG_VOLUME/${APP_NAME}"
cp -a "$TMP_BUILD/." "$DMG_VOLUME/${APP_NAME}/"
ln -sf "$FINAL_APPS_DIR" "$DMG_VOLUME/Applications"

notify-send "linapp" "Build complete. Drag the app to Applications." --icon=dialog-information
pkill -f "dolphin $DMG_VOLUME" || true
sleep 0.5
dolphin "$DMG_VOLUME" &
EOF

chmod +x "$TARGET_SCRIPT"

SHELL_RC=""
case "${SHELL:-}" in
    */zsh)  SHELL_RC="$HOME/.zshrc" ;;
    */bash) SHELL_RC="$HOME/.bashrc" ;;
esac

if [ -n "$SHELL_RC" ] && [ -f "$SHELL_RC" ]; then
    if ! grep -q "local/bin" "$SHELL_RC"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
    fi
fi

notify-send "linapp" "Installation successful! Command 'linapp' is now available." --icon=dialog-information
echo "LinApp has been installed to $TARGET_SCRIPT"
echo "Please restart your terminal or run: source $SHELL_RC"
