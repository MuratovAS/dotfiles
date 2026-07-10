#!/bin/sh
rm -r -f  ./.config
mkdir ./.config
mkdir ./.config/micro/
mkdir ./.config/micro/colorschemes

cp -r  ~/.config/xdg-desktop-portal-wlr ./.config
cp -r  ~/.config/sway ./.config
cp -r  ~/.config/waybar ./.config
rm ./.config/waybar/theme.css
cp -r  ~/.config/micro/colorschemes/everforest.micro  ./.config/micro/colorschemes/
cp -r  ~/.config/sworkstyle ./.config


cp  ~/.config/electron-flags.conf ./.config
cp  ~/.config/user-dirs.dirs ./.config
cp  ~/.profile ./

