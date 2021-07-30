#!/bin/sh
#Checks if a configuration file exists, if necessary creates 
function checkConfig(){
	if [ ! -f "$HOME/.config/wlsunset/config" ];
	then 
		mkdir -p $HOME/.config/wlsunset
echo 'temp_low="4000"
temp_high="6500"
sunrise="07:00"
sunset="23:00"
duration="900"
location="off"
' >> $HOME/.config/wlsunset/config
	fi
}

#Startup function
function onSunSet(){
	checkConfig
	source $HOME/.config/wlsunset/config

	if [ ${location} = "on" ]; 
	then
		CONTENT=$(curl -s https://freegeoip.app/json/)
		longitude=$(echo $CONTENT | jq .longitude)
		latitude=$(echo $CONTENT | jq .latitude)
		if [ -e $longitude ];
		then
			echo location ERROR: freegeoip.app
			longitude='65'
			latitude='60'
		else
			echo location OK:  $latitude $longitude
		fi	
		wlsunset -l $latitude -L $longitude -t $temp_low -T $temp_high -d $duration &
	else
		wlsunset -t $temp_low -T $temp_high  -d $duration -S $sunrise -s $sunset &
	fi

}

#Accepts managing parameter 
case $1'' in
	'off')
   	pkill wlsunset
    ;;

	'on')
	onSunSet
	;;

	'toggle')
   	if pkill -0 wlsunset
	then
		pkill wlsunset
	else
		onSunSet
	fi
    ;;
esac

#Returns a string for Waybar 
if pkill -0 wlsunset
then
	class="on"
else
	class="off"
fi	

printf '{"alt":"%s"}\n' "$class"
