#!/bin/sh
swaymsg \
  --type get_inputs | \
  jq \
    --raw-output \ '
      [
        .[] |
          select(.type == "keyboard") |
          .xkb_active_layout_name |
          select(contains("English (US)") | not)
      ] |
        first // "En"
    '
killall swaymsg > /dev/null;
swaymsg \
  --type subscribe \
  --monitor \
  --raw \
  '["input"]' | \
  jq \
    --raw-output \
    --unbuffered \ '
      select(.change == "xkb_layout") |
        .input.xkb_active_layout_name |
        sub("English \\(US\\)"; "En") | sub("Russian"; "Ru")'
