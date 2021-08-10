#!/usr/bin/env bash

dir="$HOME/.config/rofi/volume/"

rofi_command="rofi -theme $dir/volume.rasi"
volume=$(amixer get Master | grep 'Playback' | grep -o '...%' | sed 's/\[//' | sed 's/%//' | sed 's/ //'| awk '{print $1; exit}')
# Options
shutdown=""
reboot=""
lock="墳"
hibernate="婢"


# Confirmation
confirm_exit() {
	rofi -dmenu\
		-i\
		-no-fixed-num-lines\
		-p "Are You Sure? (y/n) : "\
		-theme $dir/confirm.rasi
}


# Variable passed to rofi
options="$lock"

chosen="$(echo -e "$volume%" | $rofi_command -p "$options" -dmenu)"
