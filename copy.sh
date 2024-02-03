#!/bin/sh
rm -r -f  ./.config
rm -r -f  ./.local
mkdir ./.config
mkdir ./.local
mkdir ./.local/src
mkdir ./.local/bin


cp -r  ~/.config/foot  ./.config
cp -r  ~/.config/wbg  ./.config
cp -r  ~/.config/swappy  ./.config
cp -r  ~/.config/wlsunset  ./.config
cp -r  ~/.config/lf ./.config

cp -r  ~/.config/oh-my-zsh ./.config
rm -r -f  ./.config/oh-my-zsh/cache
rm -r -f  ./.config/oh-my-zsh/.git

cp  ~/.config/user-dirs.dirs ./.config
cp  ~/.profile ./
cp  ~/.zshrc ./

cp  ~/.local/bin/*.sh ./.local/bin
cp  ~/.local/src/Makefile ./.local/src/Makefile
cp  ~/.local/src/theme.h ./.local/src/theme.h

