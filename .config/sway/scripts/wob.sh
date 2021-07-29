#!/usr/bin/env bash
# https://github.com/francma/wob/wiki/wob-wrapper-script
# returns 0 (success) if $1 is running and is attached to this sway session; else 1
is_running_on_this_screen() {
    pkill -0 $1 || return 1
    for pid in $( pgrep $1 ); do
        WOB_SWAYSOCK="$( tr '\0' '\n' < /proc/$pid/environ | awk -F'=' '/^SWAYSOCK/ {print $2}' )"
        if [[ "$WOB_SWAYSOCK" == "$SWAYSOCK" ]]; then
            return 0
        fi
    done
    return 1
}

source $1
new_value=$2

wob_pipe=~/.cache/$( basename $SWAYSOCK ).wob

[[ -p $wob_pipe ]] || mkfifo $wob_pipe

# wob does not appear in $(swaymsg -t get_msg), so:
is_running_on_this_screen wob || {
    tail -f $wob_pipe | wob $WOB_ARGUMENT &
}

[[ "$new_value" ]] && echo $new_value > $wob_pipe
