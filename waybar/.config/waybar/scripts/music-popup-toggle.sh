#!/usr/bin/env bash

PIDFILE="/tmp/waybar-music-popup.pid"
POPUP="$HOME/.config/waybar/scripts/music-popup.py"


# ------------------------------------------------------------
# Close existing popup
# ------------------------------------------------------------

if [[ -f "$PIDFILE" ]]; then

    PID="$(cat "$PIDFILE")"

    if kill -0 "$PID" 2>/dev/null; then

        kill "$PID" 2>/dev/null

        rm -f "$PIDFILE"

        exit 0
    fi

    rm -f "$PIDFILE"
fi


# ------------------------------------------------------------
# Start popup
# ------------------------------------------------------------

"$POPUP" >/tmp/waybar-music-popup.log 2>&1 &

PID=$!

echo "$PID" > "$PIDFILE"


# ------------------------------------------------------------
# Clean up when popup exits
# ------------------------------------------------------------

(
    wait "$PID" 2>/dev/null
    rm -f "$PIDFILE"
) &
