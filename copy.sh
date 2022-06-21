#!/bin/sh
rm -r -f  ./.config
mkdir ./.config

cp -r  ~/.config/wlsunset  ./.config
cp -r  ~/.config/sway ./.config
cp -r  ~/.config/wofi ./.config
cp -r  ~/.config/waybar ./.config
cp -r  ~/.config/sworkstyle ./.config
cp -r  ~/.config/lf ./.config

cp -r  ~/.config/oh-my-zsh ./.config
rm -r -f  ./.config/oh-my-zsh/cache
rm -r -f  ./.config/oh-my-zsh/.git

cp -r  ~/.config/electron-flags.conf ./.config
cp -r  ~/.config/electron17-flags.conf ./.config
cp -r  ~/.config/user-dirs.dirs ./.config
cp -r  ~/.profile ./
cp -r  ~/.zshrc ./