MIME_DIR="$HOME/.local/share/mime/packages"
DESKTOP_DIR="$HOME/.local/share/applications"
mkdir -p "$MIME_DIR" "$DESKTOP_DIR"

cat << EOF > "$DESKTOP_DIR/linapp-handler.desktop"
[Desktop Entry]
Type=Application
Name=Linapp Package Installer
Exec=linapp %f
MimeType=application/vnd.debian.binary-package;application/x-compressed-tar;application/x-gtar;application/x-appimage;
NoDisplay=true
Terminal=false
EOF
chmod +x "$DESKTOP_DIR/linapp-handler.desktop"

cat << 'EOF' > "$MIME_DIR/linapp-custom.xml"
<?xml version="1.0" encoding="utf-8"?>
<mime-info xmlns="http://freedesktop.org">
    <mime-type type="application/x-appimage">
        <comment>AppImage Application</comment>
        <glob pattern="*.AppImage"/>
        <glob pattern="*.appimage"/>
    </mime-type>
</mime-info>
EOF

update-mime-database "$HOME/.local/share/mime" >/dev/null 2>&1

MIME_CONFIG="$HOME/.config/mimeapps.list"
touch "$MIME_CONFIG"
if ! grep -q "\[Default Applications\]" "$MIME_CONFIG"; then
    echo -e "\n[Default Applications]" >> "$MIME_CONFIG"
fi

MIME_TYPES=(
    "application/vnd.debian.binary-package"
    "application/x-compressed-tar"
    "application/x-gtar"
    "application/x-tgz"
    "application/x-appimage"
)

for mime in "${MIME_TYPES[@]}"; do
    sed -i "/^${mime}=/d" "$MIME_CONFIG"
    sed -i "/\[Default Applications\]/a ${mime}=linapp-handler.desktop" "$MIME_CONFIG"
done

update-desktop-database "$DESKTOP_DIR" >/dev/null 2>&1
