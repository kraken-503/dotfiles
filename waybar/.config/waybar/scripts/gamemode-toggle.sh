#!/bin/bash
STATUS_FILE="/tmp/waybar-gamemode-status"

get_status() {
    if [ -f "$STATUS_FILE" ] && [ "$(cat "$STATUS_FILE")" = "on" ]; then
        echo "on"
    else
        echo "off"
    fi
}

hypr_performance_on() {
hyprctl eval 'hl.config({
    animations = { enabled = false },
    decoration = {
        rounding = 0,
        shadow = { enabled = false },
        blur = { enabled = false }
    },
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 1
    }
})'
}

hypr_performance_off() {
  hyprctl reload
}

toggle() {
    local current
    current=$(get_status)

    if [ "$current" = "on" ]; then
        hypr_performance_off
        pkill -SIGTERM gamemoded 2>/dev/null
        echo "off" > "$STATUS_FILE"
    else
        hypr_performance_on
        gamemoded -r &
        echo "on" > "$STATUS_FILE"
    fi
}

output() {
    local status
    status=$(get_status)

    if [ "$status" = "on" ]; then
        echo '{"text": "󰊴", "tooltip": "Game Mode: ON\n\n• gamemoded \n• animations \n• blur \n• shadows \n\nClick to restore", "class": "gamemode-on", "percentage": 100}'
    else
        echo '{"text":"", "tooltip": "Game Mode: OFF\n\nClick to enable", "class": "gamemode-off", "percentage": 0}'
    fi
}

case "$1" in
    toggle)
        toggle
        output
        ;;
    status)
        output
        ;;
    *)
        output
        ;;
esac
