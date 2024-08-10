#/bin/sh
# SYS
sh -c '[ -x "$(command -v /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1)" ] && killall polkit-gnome-authentication-agent-1 ; /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1' &
sh -c 'dbus-update-activation-environment --all' &
sh -c '[ -x "$(command -v gpgconf)" ] && sleep 10 && gpgconf --launch gpg-agent' &

# PipeWire
# sh -c '[ -x "$(command -v wireplumber)" ] && pidof -q wireplumber || wireplumber' &
sh -c '[ -x "$(command -v pipewire)" ] && killall pipewire ; sleep 0.2; pipewire' &
sh -c '[ -x "$(command -v pipewire-media-session)" ] && killall pipewire-media-session ; sleep 0.2; pipewire-media-session' &
sh -c '[ -x "$(command -v pipewire-pulse)" ] && killall pipewire-pulse ; sleep 0.2; pipewire-pulse' &

sh -c '[ -x "$(command -v /usr/lib/xdg-desktop-portal-wlr)" ] && killall xdg-desktop-portal-wlr ; sleep 5; /usr/lib/xdg-desktop-portal-wlr' &
sh -c '[ -x "$(command -v /usr/lib/xdg-desktop-portal)" ] &&  sleep 7 && /usr/lib/xdg-desktop-portal -r' &

# UI
sh -c '[ -x "$(command -v kvantum)" ] &&  kvantummanager --set $KVANTUM_THEME' &
sh -c 'gsettings set org.gnome.desktop.interface gtk-theme Everforest-Dark-Borderless'
sh -c 'gsettings set org.gnome.desktop.interface icon-theme Everforest-Dark'
sh -c 'gsettings set org.gnome.desktop.interface cursor-theme Breeze'
sh -c 'gsettings set org.gnome.desktop.interface font-name "Roboto 11"'
sh -c '[ -x "$(command -v wlsunset)" ] && sunset.sh "on"' &
sh -c '[ -x "$(command -v wbg)" ] && pidof -q wbg || wbg /home/muratovas/.config/wbg/bg.jpg' &
sh -c '[ -x "$(command -v dwlb)" ] && pidof -q dwlb || dwlb.sh' &
sh -c '[ -x "$(command -v someblocks)" ] && pidof -q someblocks || someblocks -p | dwlb -status-stdin all' &
sh -c '[ -x "$(command -v mako)" ] && killall mako; mako -c $HOME/.local/share/mako' &
# sh -c '[ -x "$(command -v noticat)" ] && pidof -q noticat || noticat -dwlb | dwlb -status-stdin all' &

# Bluetooth
sh -c '[ -x "$(command -v rfkill)" ] && rfkill unblock bluetooth' &
# sh -c '[ -x "$(command -v bluetoothctl)" ] && sleep 1 && bluetoothctl power off' &

# Extra
sh -c '[ -x "$(command -v poweralertd)" ] && pkill poweralertd; exec poweralertd -s -i "line power"' &
sh -c '[ -x "$(command -v telegram-desktop)" ] && sleep 4 && pidof -q telegram-desktop || for ((;;)) do pidof -q dwl && telegram-desktop -startintray; done' &
sh -c '[ -x "$(command -v kdeconnectd)" ] && sleep 8 && pidof -q kdeconnectd || kdeconnectd' &
# sh -c '[ -x "$(command -v kdeconnect-indicator)" ] && sleep 8 && pidof -q kdeconnect-indicator || kdeconnect-indicator' &
sh -c '[ -x "$(command -v trayscale)" ] && sleep 1 && pidof -q trayscale || trayscale --hide-window' &
sh -c '[ -x "$(command -v syncthing)" ] && sleep 8 && pidof -q syncthing || syncthing' &
sh -c '[ -x "$(command -v logitech-master.sh)" ] && pidof -q libinput-debug-events || logitech-master.sh' &
sh -c '[ -x "$(command -v wireproxy)" ] && pidof -q wireproxy || sleep 3; ~/.local/share/wireproxy/run.sh' &

gsettings set org.gnome.desktop.interface icon-theme "AdwaitaLegacy"
