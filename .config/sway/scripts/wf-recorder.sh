#!/bin/sh
if pkill -0 wf-recorder
then
	class="run"
else
	class="stop"
fi	

printf '{"alt":"%s"}\n' "$class"
