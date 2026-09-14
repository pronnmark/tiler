#!/usr/bin/env bash
# Called on yabai's window_created signal.
# Moves the new window to the rightmost display (2) and ensures it's
# tiled (not floating), unless the owning app is in the exception list.
set -uo pipefail

YABAI="/opt/homebrew/bin/yabai"
JQ="/opt/homebrew/bin/jq"
export YABAI_SOCKET="/tmp/yabai_${USER}.socket"

WID="${YABAI_WINDOW_ID:-}"
[ -z "$WID" ] && exit 0

EXCEPTIONS_REGEX='^(System Settings|System Information|Archive Utility|Tailscale|1Password|QuickTime Player)$'

sleep 0.15

INFO=$("$YABAI" -m query --windows --window "$WID" 2>/dev/null)
[ -z "$INFO" ] && exit 0

APP=$(echo "$INFO" | "$JQ" -r '.app')
CUR_DISPLAY=$(echo "$INFO" | "$JQ" -r '.display')

if echo "$APP" | grep -qE "$EXCEPTIONS_REGEX"; then
    exit 0
fi

if [ "$CUR_DISPLAY" != "2" ]; then
    "$YABAI" -m window "$WID" --display 2 2>/dev/null
    sleep 0.15
fi

IS_FLOATING=$("$YABAI" -m query --windows --window "$WID" 2>/dev/null | "$JQ" -r '.["is-floating"]')
if [ "$IS_FLOATING" = "true" ]; then
    "$YABAI" -m window "$WID" --toggle float 2>/dev/null
    sleep 0.1
fi

# --focus reliably forces proper BSP tree insertion (--toggle float
# alone does not, confirmed empirically on macOS 26 / yabai 7.1.25).
"$YABAI" -m window "$WID" --focus 2>/dev/null

exit 0
