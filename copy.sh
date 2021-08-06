#!/bin/bash
rm -r -f  ./.config    
mkdir ./.config

cp -r  ~/.config/wlsunset  ./.config/wlsunset
cp -r  ~/.config/sway ./.config/sway
cp -r  ~/.config/waybar ./.config/waybar
cp -r  ~/.config/wlogout ./.config/wlogout
cp -r  ~/.config/wofi ./.config/wofi
cp -r  ~/.config/nwg-wrapper ./.config/nwg-wrapper

cp -r  ~/.config/sworkstyle ./.config/sworkstyle
cp -r  ~/.config/flashfocus ./.config/flashfocus

cp -r  ~/.config/mc ./.config/mc
cp -r  ~/.config/micro ./.config/micro
