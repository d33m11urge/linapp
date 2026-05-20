#!/bin/bash

rm -f $HOME/.local/share/applications/linapp-installer.desktop
rm -f $HOME/.local/bin/linapp-installer
rm -f $HOME/.local/bin/linapp.png

cp ./linapp-installer.desktop $HOME/.local/share/applications/
cp ./bin/linapp-installer $HOME/.local/bin/
cp ./linapp.png $HOME/.local/bin/

sed -i 's/Exec=.\/bin\/linapp-installer %f/Exec=\/home\/'$USER'\/.local\/bin\/linapp-installer %f/g' $HOME/.local/share/applications/linapp-installer.desktop
sed -i 's/Icon=.\/linapp.png/Icon=\/home\/'$USER'\/.local\/bin\/linapp.png/g' $HOME/.local/share/applications/linapp-installer.desktop

chmod +x $HOME/.local/share/applications/linapp-installer.desktop
chmod +x $HOME/.local/bin/linapp-installer

update-desktop-database $HOME/.local/share/applications/
kbuildsycoca6 --noincremental
