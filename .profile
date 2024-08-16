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

# export TERM="xterm-256color"

# Launch WM
if [ "$XDG_SESSION_TYPE" = "tty" ] && [ "$XDG_SESSION_ID" = "1" ]; 
then
	light -S 60
	export TERM_COMMAND="foot"
	export GTK_THEME=Matcha-dark-sea
	`sleep 3 && \
	gsettings set org.gnome.desktop.interface gtk-theme Matcha-dark-sea; \
	gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' \
	gsettings set org.gnome.desktop.interface icon-theme AdwaitaLegacy; \
	gsettings set org.gnome.desktop.interface cursor-theme Breeze; \
	gsettings set org.gnome.desktop.interface font-name "Roboto 11"` &
	dbus-run-session dwl
fi
