#!/bin/bash

if command -v wpctl &> /dev/null; then
    MUTED=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -o "MUTED")
    if [ -z "$MUTED" ]; then
        echo '{"text": "•", "class": "active", "tooltip": "Microphone Active"}'
    else
        echo '{"text": "", "class": "muted", "tooltip": "Microphone Muted"}'
    fi
elif command -v pactl &> /dev/null; then
    MUTED=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
    if [ "$MUTED" = "no" ]; then
        echo '{"text": "•", "class": "active", "tooltip": "Microphone Active"}'
    else
        echo '{"text": "", "class": "muted", "tooltip": "Microphone Muted"}'
    fi
fi
