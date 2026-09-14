#!/usr/bin/env bash
# Fixes windows that yabai marked "managed" but never actually
# inserted into the BSP tree (split-type stays "none", frames don't
# move/overlap). This happens for windows that existed *before* a
# rule/space-layout change took effect.
#
# Fix: --toggle float does NOT reliably force BSP re-insertion on
# modern macOS (confirmed via yabai -V trace: the daemon message is
# sent and returns, but split-type stays "none"). --focus DOES force
# a proper re-insert into the BSP tree. So we focus each affected
# window instead, then restore the originally-focused window after.
set -uo pipefail

YABAI="/opt/homebrew/bin/yabai"
JQ="/opt/homebrew/bin/jq"
export YABAI_SOCKET="/tmp/yabai_${USER}.socket"

ORIGINAL_FOCUS=$("$YABAI" -m query --windows --window 2>/dev/null | "$JQ" -r '.id // empty')

# Only touch windows currently on display 2 (rightmost / tiled screen)
IDS=$("$YABAI" -m query --windows | "$JQ" -r '.[] | select(.display==2) | .id')

count=0
for wid in $IDS; do
    INFO=$("$YABAI" -m query --windows --window "$wid" 2>/dev/null)
    [ -z "$INFO" ] && continue
    IS_VISIBLE=$(echo "$INFO" | "$JQ" -r '.["is-visible"]')
    SPLIT_TYPE=$(echo "$INFO" | "$JQ" -r '.["split-type"]')
    IS_FLOATING=$(echo "$INFO" | "$JQ" -r '.["is-floating"]')

    # Skip dead/ghost window entries and already-tiled/floating windows
    [ "$IS_VISIBLE" = "false" ] && continue
    [ "$IS_FLOATING" = "true" ] && continue
    [ "$SPLIT_TYPE" != "none" ] && continue

    "$YABAI" -m window "$wid" --focus 2>/dev/null && count=$((count + 1))
    sleep 0.15
done

# Restore original focus if we changed it
if [ -n "$ORIGINAL_FOCUS" ]; then
    "$YABAI" -m window "$ORIGINAL_FOCUS" --focus 2>/dev/null
fi

"$YABAI" -m space --balance 2>/dev/null
echo "Retiled $count previously-untiled window(s) on display 2."
