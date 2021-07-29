#!/bin/sh
STATUS="$(playerctl status)"
SHUFFLE_STATUS="$(playerctl shuffle)"
if [[ "$SHUFFLE_STATUS" == "On" ]]; then
    SHUFFLE_ICON=""
fi

if [[ "$STATUS" != "Playing" ]]; then
    echo "$STATUS"
else
    artist="$(playerctl metadata xesam:albumArtist)"
    title="$(playerctl metadata xesam:title)"

    if [[ -n "$SHUFFLE_ICON" ]]; then
        echo "[${SHUFFLE_ICON}] ${artist} - ${title}"
        echo "[${SHUFFLE_ICON}] ${artist} - ${title}"
    else
        echo "${artist} - ${title}"
        echo "${artist} - ${title}"
    fi
fi
