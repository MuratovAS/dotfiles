#/bin/sh
echo "autostart.sh"

#SYS
sh -c '[ -x "$(command -v /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1)" ] && pidof -q polkit-gnome-authentication-agent-1 || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1' &
sh -c 'dbus-update-activation-environment --all' &
sh -c '[ -x "$(command -v gpgconf)" ] && sleep 10 && gpgconf --launch gpg-agent' &

#PipeWire
# sh -c '[ -x "$(command -v wireplumber)" ] && pidof -q wireplumber || wireplumber' &
sh -c '[ -x "$(command -v pipewire)" ] && pidof -q pipewire || sleep 0.2; pipewire' &
sh -c '[ -x "$(command -v pipewire-media-session)" ] && pidof -q pipewire-media-session || sleep 0.2; pipewire-media-session' &
sh -c '[ -x "$(command -v pipewire-pulse)" ] && pidof -q pipewire-pulse || sleep 0.2; pipewire-pulse' &

sh -c '[ -x "$(command -v /usr/lib/xdg-desktop-portal-wlr)" ] && pidof -q xdg-desktop-portal-wlr || sleep 5; /usr/lib/xdg-desktop-portal-wlr' &
sh -c '[ -x "$(command -v /usr/lib/xdg-desktop-portal)" ] &&  sleep 7 && /usr/lib/xdg-desktop-portal -r' &

#UI
sh -c '[ -x "$(command -v wlsunset)" ] && sunset.sh "on"' &
sh -c 'gsettings set org.gnome.desktop.interface gtk-theme Everforest-Dark-Borderless'
sh -c 'gsettings set org.gnome.desktop.interface icon-theme Everforest-Dark'
sh -c 'gsettings set org.gnome.desktop.interface cursor-theme Breeze'
sh -c 'gsettings set org.gnome.desktop.interface font-name "Roboto 11"'

# bluetooth
sh -c '[ -x "$(command -v rfkill)" ] && rfkill unblock bluetooth' &
sh -c '[ -x "$(command -v bluetoothctl)" ] && sleep 1 && bluetoothctl power off' &

#extra
# sh -c '[ -x "$(command -v ~/.local/share/wireproxy/wireproxy)" ] && sleep 3 && ~/.local/share/wireproxy/run.sh' &

sh -c '[ -x "$(command -v poweralertd)" ] && pkill poweralertd; exec poweralertd -s -i "line power"' &
sh -c '[ -x "$(command -v telegram-desktop)" ] && sleep 4 && pidof -q telegram-desktop || for ((;;)) do telegram-desktop -startintray; done' &
sh -c '[ -x "$(command -v kdeconnect-indicator)" ] && sleep 8 && pidof -q kdeconnect-indicator || kdeconnect-indicator' &
sh -c '[ -x "$(command -v trayscale)" ] && sleep 1 && pidof -q trayscale || trayscale --hide-window' &
sh -c '[ -x "$(command -v syncthing)" ] && sleep 8 && pidof -q syncthing || syncthing' &
sh -c '[ -x "$(command -v logitech-master.sh)" ] && pidof -q libinput-debug-events || logitech-master.sh' &
sh -c '[ -x "$(command -v wireproxy)" ] && pidof -q wireproxy || sleep 3; ~/.local/share/wireproxy/run.sh' &
