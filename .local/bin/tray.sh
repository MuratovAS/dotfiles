#/bin/sh

playerctl status | sed "s/Playing/^rm(playerctl next)^lm(playerctl play-pause; pkill -RTMIN+8 someblocks)󰐌 /" | \
                   sed "s/Paused/^lm(playerctl play-pause; pkill -RTMIN+8 someblocks)󰏥 /"  | tr -d "\n" && printf "^rm()^lm()"
pidof -q wf-recorder && printf "^lm(killall -s SIGINT wf-recorder && pkill -RTMIN+8 someblocks) ^lm()"
ip addr show wlan0 | grep "inet" > /dev/null && printf "^lm($TERM nmtui)󰖩 ^lm()"
ip addr show eth0 | grep "inet" > /dev/null && printf "^lm($TERM nmtui)󰒍 ^lm()"
printf "^lm($TERM bluetuith) ^lm()"
sunset.sh
printf "/ "
pidof -q dockerd && printf "^lm($HOME lazydocker)󰡨 ^lm()"
pidof -q libvirtd && printf "^lm(virt-manager) ^lm()"
pidof -q cupsd && printf "^lm()󰐪 ^lm()"
ip addr show tailscale0 > /dev/null && tmp=`tailscale status` && printf "^lm(trayscale)󰱓 ^lm()" || printf "^lm(trayscale)󰅛 ^lm()"
# syncthingctl | sed -n 2p
if [[ $(kdeconnect-cli -a  --name-only) == 'pixel7' ]]; then printf "^lm(kdeconnect-app) ^lm()"; fi
pidof -q syncthing && syncthingctl --no-color -s | head -2 | grep -q -o "Status.*idle" && printf "^lm(xdg-open http://127.0.0.1:8384/) ^lm()" || printf "^lm(xdg-open http://127.0.0.1:8384/)󰓧 ^lm()"
pidof -q telegram-desktop && printf "^lm(telegram-desktop)^lm()"

                   