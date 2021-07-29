#!/bin/sh
if pkill -0 wlsunset
then
	class="on"
else
	class="off"
fi	

printf '{"alt":"%s"}\n' "$class"
