#!/usr/bin/env bash

# style_8

dir="$HOME/.config/rofi/launcher_text"
theme="style_8"

rofi -no-lazy-grab -show drun -modi drun  -theme $dir/"$theme"
