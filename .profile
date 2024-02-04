#!/bin/sh
# Default
export EDITOR=micro
export VISUAL=micro

# Java theme
export _JAVA_AWT_WM_NONREPARENTING=1

# GTK wayland 
export GTK_CSD=0

# QT wayland
export QT_QPA_PLATFORMTHEME=qt5ct
export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
export QT_QPA_PLATFORM="wayland"
#export QT_QPA_PLATFORM="xcb"

# fix for VMSVGA graphics controller 
#export WLR_NO_HARDWARE_CURSORS=1

# App
## micro
export MICRO_TRUECOLOR=1

## firefox
export MOZ_ENABLE_WAYLAND=1
export MOZ_DBUS_REMOTE=1

## pass
source ~/.password-store

## gpg
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

# Launch WM
if [ "$(tty)" = "/dev/tty1" ] && [ "$XDG_SESSION_TYPE" = "tty" ] && [ "$XDG_SESSION_ID" = "1" ]; ; 
then
	light -S 60
	# export GTK_THEME=Matcha-dark-sea 
	# export XDG_SESSION_DESKTOP=sway
	# export XDG_CURRENT_DESKTOP=sway
	# dbus-run-session sway
	
	export TERM="foot"
	export KVANTUM_THEME=Matcha-sea-dark 
	export GTK_THEME=Matcha-dark-sea
	dbus-run-session dwl
fi
