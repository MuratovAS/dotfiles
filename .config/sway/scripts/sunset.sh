#!/bin/sh
#CONTENT=$(curl -s https://freegeoip.app/json/)
#longitude=$(echo $CONTENT | jq .longitude)
#latitude=$(echo $CONTENT | jq .latitude)
#if $CONTENT
#then
#	echo ERROR: freegeoip.app
#	longitude='65'
#	latitude='60'
#else
#	echo OK:  $latitude $longitude	
#fi	
#wlsunset -l $latitude -L $longitude 

if [ $1'' == 'toggle' ]
then
	if pkill -0 wlsunset
	then
		pkill wlsunset
	else
		wlsunset -t 4000 -T 6500  -S 07:00 -s 23:00 -d 900 &
	fi	
fi	
