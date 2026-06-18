#!/bin/bash
# sway-nav.sh
#
# Direction-based focus/move navigation with workspace fallback, aware of
# per-monitor workspace ranges read from Waybar's persistent-workspaces.
#
# FOCUS mode:
#   1. Try sway's native focus <direction>. If it lands on a window
#      (possibly on a different monitor) — done, normal navigation.
#   2. If sway jumped focus to a different monitor without landing on an
#      actual window there (or focus didn't move at all) — revert/stay,
#      and instead cycle to the next/previous workspace, restricted to
#      the CURRENT monitor's configured range.
#
# MOVE mode:
#   1. Try sway's native move <direction> on the focused container.
#   2. If sway moved the container to a different monitor, or the move
#      had no effect at all (edge of the layout, e.g. only one window) —
#      send the container directly (by id) to the next/previous
#      workspace NUMBER on the CURRENT monitor only, and follow it
#      (switch the view to that workspace). The container is positioned
#      at the edge of the destination workspace matching the side it
#      entered from (e.g. moving right makes it enter from the left).
#
# In both modes, a workspace belonging to a different monitor is never
# reached this way, for any direction.
#
# Usage:
#   sway-nav.sh <focus|move> <left|right|up|down>
#
# Requires: jq, python3, bash 4+
# Requires: focus_wrapping no   in sway config
# Optional: export WAYBAR_CONFIG=/path/to/config.jsonc if non-standard

usage() {
    echo "Usage: $(basename "$0") <focus|move> <left|right|up|down>" >&2
}

mode="$1"
dir="$2"

case "$mode" in
    focus|move) ;;
    *) usage; exit 1 ;;
esac

case "$dir" in
    right|down) sign=1 ;;
    left|up) sign=-1 ;;
    *) usage; exit 1 ;;
esac

get_focused_id() {
    swaymsg -t get_tree | jq '.. | objects | select(.focused == true) | .id'
}

# Floating windows don't participate in the tiling tree / workspace
# layout the way tiled containers do, so all the monitor-boundary logic
# below doesn't apply to them. If the focused window is floating, just
# let sway do its normal thing — focus switches to another window, move
# repositions it on screen — and skip everything else.
is_focused_floating() {
    local t
    t=$(swaymsg -t get_tree | jq -r '.. | objects | select(.focused == true) | .type')
    [ "$t" == "floating_con" ]
}

if is_focused_floating; then
    if [ "$mode" == "move" ]; then
        swaymsg move "$dir" >/dev/null
    else
        swaymsg focus "$dir" >/dev/null
    fi
    exit 0
fi

get_focused_output() {
    swaymsg -t get_outputs | jq -r '.[] | select(.focused == true) | .name'
}

get_focused_ws_num() {
    swaymsg -t get_workspaces | jq '.[] | select(.focused == true) | .num'
}

get_focused_rect() {
    swaymsg -t get_tree | jq -c '.. | objects | select(.focused == true) | .rect'
}

# Checks whether, within workspace number $2, there is some OTHER window
# positioned in direction $1 relative to the currently focused one (with
# the appropriate overlap on the other axis) — i.e. whether sway's native
# focus/move <direction> would find a target locally, without needing to
# escape to a different output. Used to decide whether it's even worth
# attempting the native command, so we never let the compositor visibly
# flash the window/cursor onto another monitor only to correct it back.
has_local_target() {
    local dir="$1" ws_num="$2"
    swaymsg -t get_tree | jq -e --arg dir "$dir" --argjson wsnum "$ws_num" '
        ([.. | objects | select(.type == "workspace" and .num == $wsnum)] | .[0]) as $ws |
        ($ws // {nodes: [], floating_nodes: []}) as $ws |
        ($ws | [.. | objects | select(
            ((.nodes // []) == []) and ((.floating_nodes // []) == []) and
            (.type == "con" or .type == "floating_con") and
            ((.rect.width // 0) > 0) and ((.rect.height // 0) > 0)
        )]) as $leaves |
        ($leaves | map(select(.focused == true)) | .[0]) as $f |
        if ($f == null) then false else
            ($f.rect) as $fr |
            ($leaves | map(select(.focused != true)) | any(
                (.rect) as $r |
                if $dir == "right" then
                    ($r.x >= $fr.x + $fr.width) and ($r.y < $fr.y + $fr.height) and ($r.y + $r.height > $fr.y)
                elif $dir == "left" then
                    ($r.x + $r.width <= $fr.x) and ($r.y < $fr.y + $fr.height) and ($r.y + $r.height > $fr.y)
                elif $dir == "down" then
                    ($r.y >= $fr.y + $fr.height) and ($r.x < $fr.x + $fr.width) and ($r.x + $r.width > $fr.x)
                else
                    ($r.y + $r.height <= $fr.y) and ($r.x < $fr.x + $fr.width) and ($r.x + $r.width > $fr.x)
                end
            ))
        end
    ' >/dev/null 2>&1
}

# Prints the ids of the direct children of workspace number $1, in
# their current order, one per line.
get_ws_children_ids() {
    local num="$1"
    swaymsg -t get_tree | jq -r "[.. | objects | select(.type == \"workspace\" and .num == $num)] | (.[0].nodes // [])[] | .id"
}

# Pushes container $1 (by id) to the front (index 0) or back (last
# index) of workspace $2's children, depending on $3 (a direction:
# right/down -> front, since it entered from the left/top; left/up ->
# back, since it entered from the right/bottom). Doesn't assume which
# of sway's "move next"/"move prev" decreases the index — it probes
# with one call and adapts, so it's correct regardless.
position_at_edge() {
    local container_id="$1" target="$2" dir="$3"
    local ids cur_idx i

    mapfile -t ids < <(get_ws_children_ids "$target")
    local n=${#ids[@]}
    [ "$n" -le 1 ] && return

    cur_idx=-1
    for i in "${!ids[@]}"; do
        if [ "${ids[$i]}" == "$container_id" ]; then
            cur_idx=$i
            break
        fi
    done
    [ "$cur_idx" -eq -1 ] && return

    # desired_idx: which end of the children list we want to land on.
    # push_dir: the geometric move that should walk us toward it. Unlike
    # move <next|prev> (which had no effect for some layouts in testing),
    # move <left|right|up|down> is the same primitive already used and
    # verified elsewhere in this script for in-workspace swaps.
    local desired_idx push_dir
    case "$dir" in
        right) desired_idx=0; push_dir="left" ;;
        left) desired_idx=$((n - 1)); push_dir="right" ;;
        down) desired_idx=0; push_dir="up" ;;
        up) desired_idx=$((n - 1)); push_dir="down" ;;
    esac

    local guard=0
    while [ "$cur_idx" -ne "$desired_idx" ] && [ "$guard" -lt "$n" ]; do
        guard=$((guard + 1))
        swaymsg "[con_id=$container_id] move $push_dir" >/dev/null

        mapfile -t ids < <(get_ws_children_ids "$target")
        local new_idx=-1
        for i in "${!ids[@]}"; do
            if [ "${ids[$i]}" == "$container_id" ]; then
                new_idx=$i
                break
            fi
        done

        if [ "$new_idx" -eq -1 ]; then
            # The container is no longer among this workspace's direct
            # children — it escaped to another output. Bring it straight
            # back; never leave it stranded elsewhere.
            swaymsg "[con_id=$container_id] move container to workspace number $target" >/dev/null
            break
        fi

        if [ "$new_idx" -eq "$cur_idx" ]; then
            # No further progress possible — stop here instead of
            # issuing another call that could risk escaping outward.
            break
        fi

        cur_idx=$new_idx
    done
}

# Find the waybar config file (JSON or JSONC).
find_waybar_config() {
    local candidates=(
        "$WAYBAR_CONFIG"
        "$HOME/.config/waybar/config.jsonc"
        "$HOME/.config/waybar/config"
        "/etc/xdg/waybar/config.jsonc"
        "/etc/xdg/waybar/config"
    )
    local c
    for c in "${candidates[@]}"; do
        [ -n "$c" ] && [ -f "$c" ] && { echo "$c"; return 0; }
    done
    return 1
}

# Parses the waybar config and prints lines:
#   <output_name> <ws_num1> <ws_num2> ...
parse_waybar_workspaces() {
    local cfg="$1"
    python3 - "$cfg" << 'PYEOF'
import sys, re, json

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
except OSError:
    sys.exit(1)

def strip_jsonc(s):
    out = []
    i, n = 0, len(s)
    in_string = False
    while i < n:
        c = s[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(s[i + 1])
                i += 2
                continue
            if c == '"':
                in_string = False
            i += 1
            continue
        if c == '"':
            in_string = True
            out.append(c)
            i += 1
            continue
        if c == '/' and i + 1 < n and s[i + 1] == '/':
            while i < n and s[i] != '\n':
                i += 1
            continue
        if c == '/' and i + 1 < n and s[i + 1] == '*':
            i += 2
            while i + 1 < n and not (s[i] == '*' and s[i + 1] == '/'):
                i += 1
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)

clean = strip_jsonc(text)
# JSONC (waybar) tolerates trailing commas before } or ] — strict JSON does not.
clean = re.sub(r',(\s*[}\]])', r'\1', clean)

pw_dicts = []

try:
    data = json.loads(clean)
except json.JSONDecodeError as e:
    print(f"sway-nav: failed to parse waybar config {path}: {e}", file=sys.stderr)
    data = None

if data is not None:
    configs = data if isinstance(data, list) else [data]
    for cfg in configs:
        if not isinstance(cfg, dict):
            continue
        for key, val in cfg.items():
            if not key.startswith("sway/workspaces"):
                continue
            if not isinstance(val, dict):
                continue
            pw = val.get("persistent-workspaces") or val.get("persistent_workspaces")
            if isinstance(pw, dict):
                pw_dicts.append(pw)


def extract_commented_pw(raw_text):
    """
    Finds persistent-workspaces / persistent_workspaces blocks that are
    entirely commented out line-by-line with '//' (waybar/editor style:
    every line of the block, including the key line, starts with '//'),
    strips the '//' prefix from each line, and parses the result as JSON.
    Returns a dict (possibly empty) in the same shape as the real value.
    """
    lines = raw_text.split("\n")
    n = len(lines)
    key_re = re.compile(r'^\s*//\s*"(persistent-workspaces|persistent_workspaces)"\s*:\s*(\{.*)$')
    found = {}
    i = 0
    while i < n:
        m = key_re.match(lines[i])
        if not m:
            i += 1
            continue
        block = [m.group(2)]
        depth = block[0].count('{') - block[0].count('}')
        j = i + 1
        closed = depth <= 0
        while not closed and j < n:
            stripped = lines[j].lstrip()
            if not stripped.startswith('//'):
                break
            content = stripped[2:]
            if content.startswith(' '):
                content = content[1:]
            block.append(content)
            depth += content.count('{') - content.count('}')
            if depth <= 0:
                closed = True
            j += 1
        if closed:
            fragment = "\n".join(block)
            d, end_pos = 0, None
            for idx, ch in enumerate(fragment):
                if ch == '{':
                    d += 1
                elif ch == '}':
                    d -= 1
                    if d == 0:
                        end_pos = idx
                        break
            if end_pos is not None:
                fragment = fragment[:end_pos + 1]
                fragment = re.sub(r',(\s*[}\]])', r'\1', fragment)
                try:
                    value = json.loads(fragment)
                    if isinstance(value, dict):
                        found.update(value)
                except json.JSONDecodeError:
                    pass
            i = j
            continue
        i += 1
    return found


commented_pw = extract_commented_pw(text)
if commented_pw:
    pw_dicts.append(commented_pw)

result = {}
for pw in pw_dicts:
    for ws_name, outputs in pw.items():
        if not isinstance(outputs, list) or not outputs:
            continue
        m = re.match(r'^(\d+)', str(ws_name))
        if not m:
            continue
        num = m.group(1)
        for out in outputs:
            result.setdefault(out, set()).add(int(num))

for out, nums in result.items():
    print(out + " " + " ".join(str(n) for n in sorted(nums)))
PYEOF
}

declare -A OUTPUT_WORKSPACES
cfg_path=$(find_waybar_config)
if [ -n "$cfg_path" ]; then
    while read -r output rest; do
        [ -n "$output" ] || continue
        OUTPUT_WORKSPACES["$output"]="$rest"
    done < <(parse_waybar_workspaces "$cfg_path")
fi

# Computes the target workspace number for $output, given a reference
# workspace number $cur_override (or the live current one, if omitted).
# Echoes a number, "" (already at the edge of this monitor's range), or
# "__NONUMERIC__" (reference workspace has no numeric id).
compute_target_ws() {
    local output="$1"
    local cur_override="$2"
    local list=(${OUTPUT_WORKSPACES[$output]})
    local cur

    if [ -n "$cur_override" ]; then
        cur="$cur_override"
    else
        cur=$(get_focused_ws_num)
    fi

    if [ "$cur" -lt 0 ]; then
        echo "__NONUMERIC__"
        return
    fi

    if [ "${#list[@]}" -eq 0 ]; then
        # No explicit range found for this output in the waybar config —
        # fall back to plain arithmetic on the workspace number, so empty
        # workspaces are still reachable (just without per-monitor bounds).
        local target
        target=$((cur + sign))
        if [ "$target" -lt 1 ]; then
            target=1
        fi
        echo "$target"
        return
    fi

    local idx=-1 i
    for i in "${!list[@]}"; do
        if [ "${list[$i]}" -eq "$cur" ]; then
            idx=$i
            break
        fi
    done

    if [ "$idx" -eq -1 ]; then
        echo "${list[0]}"
        return
    fi

    local new_idx=$((idx + sign))
    if [ "$new_idx" -lt 0 ] || [ "$new_idx" -ge "${#list[@]}" ]; then
        # Already at the edge of this output's workspace range.
        echo ""
        return
    fi

    echo "${list[$new_idx]}"
}

# Switches the active workspace to the computed target — used for FOCUS
# mode. At this point focus has already been put back on $output, so a
# live query inside compute_target_ws is fine.
apply_focus_fallback() {
    local output="$1"
    local target
    target=$(compute_target_ws "$output" "")

    if [ "$target" == "__NONUMERIC__" ]; then
        if [ "$sign" -gt 0 ]; then
            swaymsg workspace next_on_output
        else
            swaymsg workspace prev_on_output
        fi
    elif [ -n "$target" ]; then
        swaymsg workspace number "$target"
    fi
    # empty target: at the edge of this monitor's range, do nothing.
}

# Sends the container identified by $container_id to the next/previous
# workspace on $output, computed from $origin_ws (the workspace number
# it was on BEFORE sway's native move attempt — never re-queried live,
# since a cross-output move can drag an entire workspace along and make
# "currently focused" data unreliable). Used for MOVE mode.
apply_move_fallback() {
    local output="$1"
    local container_id="$2"
    local origin_ws="$3"
    local target
    target=$(compute_target_ws "$output" "$origin_ws")

    # Refocus the original monitor first, so that if the target workspace
    # doesn't exist yet, sway creates it there (not wherever focus drifted
    # to during the native move attempt).
    swaymsg focus output "$output" >/dev/null

    if [ "$target" == "__NONUMERIC__" ] || [ -z "$target" ]; then
        # Either can't compute (non-numeric origin) or already at the edge
        # of this monitor's range — restore the container to where it was,
        # never letting it stay on a different monitor.
        swaymsg "[con_id=$container_id] move container to workspace number $origin_ws" >/dev/null
        swaymsg workspace number "$origin_ws"
        return
    fi

    swaymsg "[con_id=$container_id] move container to workspace number $target" >/dev/null

    # Position the window at the edge corresponding to the direction it
    # came from (e.g. moving right makes it enter from the left side of
    # the destination workspace).
    position_at_edge "$container_id" "$target" "$dir"

    # Follow the window to the destination workspace.
    swaymsg workspace number "$target"
}

before_output=$(get_focused_output)

if [ "$mode" == "move" ]; then
    before_id=$(get_focused_id)
    origin_ws=$(get_focused_ws_num)

    local_target=1
    if [ "$origin_ws" -ge 0 ]; then
        if has_local_target "$dir" "$origin_ws"; then
            local_target=0
        fi
    fi

    if [ "$local_target" -eq 1 ]; then
        # No window positioned in this direction within the current
        # workspace — sway's native move would either have no effect or
        # escape to another monitor either way. Skip it entirely: no
        # point letting the compositor visibly flash the window onto
        # another screen just to correct it afterwards.
        apply_move_fallback "$before_output" "$before_id" "$origin_ws"
    else
        before_rect=$(get_focused_rect)

        swaymsg move "$dir" >/dev/null

        after_output=$(get_focused_output)
        after_rect=$(get_focused_rect)

        if [ "$before_output" != "$after_output" ]; then
            # Sway escaped the container to a different monitor (possibly
            # dragging its whole workspace along) — send it directly to
            # the computed target workspace on the ORIGINAL monitor by
            # id, instead of relying on focus state that may now be
            # unreliable.
            apply_move_fallback "$before_output" "$before_id" "$origin_ws"
        elif [ "$before_rect" == "$after_rect" ]; then
            # Move had no effect at all (no sibling to swap with in this
            # direction, and no neighboring monitor to escape to either)
            # — edge of this monitor's layout, send the container to the
            # next/prev workspace on THIS monitor instead.
            apply_move_fallback "$before_output" "$before_id" "$origin_ws"
        fi
        # Otherwise: native move succeeded normally within the same
        # monitor (e.g. swapped with a sibling) — leave it as-is.
    fi
else
    before_id=$(get_focused_id)
    origin_ws_focus=$(get_focused_ws_num)

    local_target=1
    if [ "$origin_ws_focus" -ge 0 ]; then
        if has_local_target "$dir" "$origin_ws_focus"; then
            local_target=0
        fi
    fi

    if [ "$local_target" -eq 1 ]; then
        # No window positioned in this direction within the current
        # workspace — focus has nowhere to go locally, so skip the
        # native attempt and its visible flicker.
        apply_focus_fallback "$before_output"
    else
        swaymsg focus "$dir" >/dev/null

        after_id=$(get_focused_id)
        after_output=$(get_focused_output)

        if [ "$before_output" != "$after_output" ]; then
            # Sway moved focus to a different monitor — revert that and
            # switch workspace on the ORIGINAL monitor instead.
            swaymsg focus output "$before_output" >/dev/null
            apply_focus_fallback "$before_output"
        elif [ "$before_id" == "$after_id" ]; then
            # Focus didn't change — edge of windows on this monitor.
            apply_focus_fallback "$before_output"
        fi
    fi
fi