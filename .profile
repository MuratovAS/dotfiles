#!/bin/sh
# make default editor
export EDITOR=micro
export VISUAL=micro
export MICRO_TRUECOLOR=1

#Electron
export XDG_CONFIG_HOME=$HOME/.config

#Java theme
export _JAVA_AWT_WM_NONREPARENTING=1

# Most pure GTK3 apps use wayland by default, but some,
# like Firefox, need the backend to be explicitely selected.
export MOZ_ENABLE_WAYLAND=1
export MOZ_DBUS_REMOTE=1
export GTK_CSD=0

# QT wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
export QT_QPA_PLATFORM="wayland"
#export QT_SCALE_FACTOR="1.2"
#export QT_QPA_PLATFORM="xcb"

# Hardware token
#export GPG_TTY="$(tty)"
#export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
#gpgconf --launch gpg-agent


# launch WM
if [ -z $DISPLAY ] && [ "$XDG_SESSION_TYPE" = "tty" ] && [ "$XDG_SESSION_ID" = "1" ]; 
then
	export XDG_SESSION_DESKTOP=sway
	dbus-launch sway
fi