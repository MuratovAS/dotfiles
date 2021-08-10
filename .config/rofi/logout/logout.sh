#!/usr/bin/env bash

dir="$HOME/.config/rofi/logout/"

uptime=$(uptime -p | sed -e 's/up //g')
cpu=$(sh $dir/usedcpu)
memory=$(sh $dir/usedram)
rofi_command="rofi -theme $dir/logout.rasi"

# Options
shutdown=""
reboot=""
lock=""
hibernate="拉"
logout=""

# Confirmation
confirm_exit() {
	rofi -dmenu\
		-i\
		-no-fixed-num-lines\
		-p "Are You Sure? (y/n) : "\
		-theme $dir/confirm.rasi
}


# Variable passed to rofi
options="$shutdown\n$reboot\n$lock\n$hibernate\n$logout"

chosen="$(echo -e "$options" | $rofi_command -p "祥  $uptime  |   $cpu  |  ﬙ $memory " -dmenu -selected-row 0)"
case $chosen in
    $shutdown)
		#ans=$(confirm_exit &)
		#if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			systemctl poweroff
		#else
		#	exit 0
        #fi
        ;;
    $reboot)
		#ans=$(confirm_exit &)
		#if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			systemctl reboot
		#else
		#	exit 0
        #fi
        ;;
    $lock)
		swaymsg exec '$locking'
        ;;
    $hibernate)
		#ans=$(confirm_exit &)
		#if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			systemctl hibernate
		#else
		#	exit 0
        #fi
        ;;
    $logout)
		#ans=$(confirm_exit &)
		#if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			loginctl terminate-user $USER	
		#else
		#	exit 0
        #fi
        ;;
esac
