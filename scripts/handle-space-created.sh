#!/usr/bin/env bash
# Called on yabai's space_created signal.
# Sets the new space's layout to bsp if it's on display 2 (rightmost),
# otherwise float.
set -uo pipefail

YABAI="/opt/homebrew/bin/yabai"
JQ="/opt/homebrew/bin/jq"
export YABAI_SOCKET="/tmp/yabai_${USER}.socket"

SID="${YABAI_SPACE_ID:-}"
[ -z "$SID" ] && exit 0

DISPLAY_IDX=$("$YABAI" -m query --spaces --space "$SID" 2>/dev/null | "$JQ" -r '.display')

if [ "$DISPLAY_IDX" = "2" ]; then
    "$YABAI" -m space "$SID" --layout bsp 2>/dev/null
else
    "$YABAI" -m space "$SID" --layout float 2>/dev/null
fi
