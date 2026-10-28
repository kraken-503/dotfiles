#!/usr/bin/env bash

if ! pgrep -x "obs" > /dev/null; then
    echo ""
    exit 0
fi

#keep in mind that, in my config, i set the Screenrecording output to the ~/Videos/Screenrecords/ DIR
#change your Screenrecording output directory correctly below

DIR="$HOME/Videos/Screenrecords/"

FILE=$(find "$DIR" -type f \( -name "*.mkv" -o -name "*.mp4" \) -printf '%T@ %p\n' 2>/dev/null |
    sort -nr |
    head -n 1 |
    cut -d' ' -f2-)

if [ -n "$FILE" ] && [ "$(find "$FILE" -mmin -0.05 2>/dev/null)" ]; then
    echo '{"text":"󰻃","alt":"recording","tooltip":"OBS is recording","class":["recording"]}'
else
    echo '{"text":"󰻂","alt":"idle","tooltip":"OBS is open (Not recording)","class":["idle"]}'
fi
