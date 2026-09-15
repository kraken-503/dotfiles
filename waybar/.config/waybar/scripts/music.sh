#!/usr/bin/env bash

# ------------------------------------------------------------
# Waybar compact MPRIS player
# ------------------------------------------------------------

if ! playerctl status &>/dev/null; then
    echo '{"text":"󰎆","tooltip":"No music player"}'
    exit 0
fi


STATUS="$(playerctl status 2>/dev/null)"

TITLE="$(playerctl metadata --format '{{ title }}' 2>/dev/null)"

ARTIST="$(playerctl metadata --format '{{ artist }}' 2>/dev/null)"

ALBUM="$(playerctl metadata --format '{{ album }}' 2>/dev/null)"


# ------------------------------------------------------------
# Nothing playing
# ------------------------------------------------------------

if [[ -z "$TITLE" ]]; then
    echo '{"text":"󰎆","tooltip":"Nothing playing"}'
    exit 0
fi


# ------------------------------------------------------------
# Player icon
# ------------------------------------------------------------

case "$STATUS" in

    Playing)
        ICON="󰐊"
        ;;

    Paused)
        ICON="󰏤"
        ;;

    *)
        ICON="󰓛"
        ;;

esac


# ------------------------------------------------------------
# Compact text
# ------------------------------------------------------------

TEXT="$ICON  $TITLE"

if [[ -n "$ARTIST" ]]; then
    TEXT="$TEXT  ·  $ARTIST"
fi


# Prevent gigantic titles from destroying the bar.

if (( ${#TEXT} > 45 )); then
    TEXT="${TEXT:0:42}..."
fi


# ------------------------------------------------------------
# Tooltip
# ------------------------------------------------------------

TOOLTIP="$TITLE"

if [[ -n "$ARTIST" ]]; then
    TOOLTIP="$TOOLTIP\n$ARTIST"
fi

if [[ -n "$ALBUM" ]]; then
    TOOLTIP="$TOOLTIP\n$ALBUM"
fi

TOOLTIP="$TOOLTIP\n\n$STATUS"


# ------------------------------------------------------------
# JSON
# ------------------------------------------------------------

jq -cn \
    --arg text "$TEXT" \
    --arg tooltip "$TOOLTIP" \
    --arg status "$STATUS" \
    '{
        text: $text,
        tooltip: $tooltip,
        class: $status
    }'

