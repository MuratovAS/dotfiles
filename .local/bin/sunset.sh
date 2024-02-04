#!/bin/bash
function start(){
	[[ -f "$HOME/.config/wlsunset/config" ]] && source "$HOME/.config/wlsunset/config"
	temp_low=${temp_low:-"5000"}
	temp_high=${temp_high:-"6500"}
	duration=${duration:-"900"}
	sunrise=${sunrise:-"07:00"}
	sunset=${sunset:-"23:00"}
	wlsunset -t $temp_low -T $temp_high -d $duration -S $sunrise -s $sunset &
}

case $1'' in
	'off')
   	pkill wlsunset
	;;
	'on')
	start
	;;
	'toggle')
   	if pkill -0 wlsunset
	then
		pkill wlsunset
	else
		start
	fi
	;;
	'check')
	command -v wlsunset
	exit $?
	;;
esac

if pkill -0 wlsunset
then
	class="^lm(sunset.sh toggle; pkill -RTMIN+8 someblocks)󱩷 ^lm()"
else
	class="^lm(sunset.sh toggle; pkill -RTMIN+8 someblocks)󱓤 ^lm()"
fi	
printf "$class"
