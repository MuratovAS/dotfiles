#!/bin/bash
#source $1
#export SWAYSOCK=(ls /run/user/1000/sway-ipc.* | head -n 1)
EVENT_SIDE1="swaymsg workspace next_on_output"
EVENT_SIDE2="swaymsg workspace prev_on_output"
#EVENT_SCROLL_UP="swaymsg exec playerctl previous"
#EVENT_SCROLL_DOWN="swaymsg exec playerctl next"
#EVENT_THUMB="exec playerctl play-pause"

function pressCommand(){
    device=$1; button=$2; key_state=$3
	#echo "Press key [" $device "/" $button "/" $key_state "]"
    if [ ${key_state} = "pressed," ]; then
		 if [ ${button} = "BTN_EXTRA" ]; then
			echo "BTN_EXTRA"
			#####
			$EVENT_SIDE1
			#####
		 elif [ ${button} = "BTN_SIDE" ]; then
		  	echo "BTN_SIDE"
		  	#####
			$EVENT_SIDE2
			#####
		 fi 		
    fi
}

function scrollCommand(){
	device=$1; vert=$2; horiz=$3
	if [ ${horiz} != "0.00/0" ]; then
		#echo "Scroll horiz [" $device "/" $horiz "]"
		if [[ ${horiz} = "-30.00"* ]]; then
			echo "SCROLL_HORIZ_UP"
			######
			$EVENT_SCROLL_UP
			######
		elif [[ ${horiz} = "30.00"* ]]; then
			echo "SCROLL_HORIZ_DOWN"
			#####
			$EVENT_SCROLL_DOWN
			#####
		fi
	#else
		#echo "Scroll vert [" $device "/" $vert "]"
	fi
}

count=0
function thumbCommand(){
	device=$1;
	if [  ${count} = 6  ]; then
		echo "BTN_THUMB"
		######
		$EVENT_THUMB
		######
		count=0
	fi
}

function parseEventLine(){
	if [ $# = 0 ]; then
		return
	fi
    device=$1
    action=$2
	if [ ${action} = "POINTER_BUTTON" ]; then
		button=$4
		key_state=$6
		pressCommand ${device} ${button} ${key_state}
	elif [ ${action} = "POINTER_SCROLL_WHEEL" ]; then
		vert=$5
		horiz=$7
		scrollCommand ${device} ${vert} ${horiz}
	elif [ ${action} = "KEYBOARD_KEY" ]; then
		thumbCommand ${device} 
	#elif [ ${action} = "POINTER_MOTION" ]; then
	#   	echo "POINTER_MOTION"
	#else
	#  	echo "Unknown action"
	fi
}

function mapDevice(){
	device=$1
	if [ -e $1 ]; then
		echo "mapDevice() ["$device"]"
		while read line; do
			parseEventLine ${line}
		done < <(stdbuf -oL sudo libinput debug-events --device ${device} & )
	else
		echo "Stream $1 does not exist"
		#return;
	fi
}

echo "Scan device"
readarray -t devices <<<$(sudo libinput list-devices | grep pointer -B4 | grep "Logitech MX Master 3" -A1 | grep -o '/dev/input/event[0-9]*')
for device in ${devices[@]}; do
	( mapDevice ${device} ) &
done

wait
