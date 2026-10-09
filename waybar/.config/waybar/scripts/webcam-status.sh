#!/bin/bash

if fuser /dev/video0 >/dev/null 2>&1; then
    echo '{"text": "", "alt": "active", "tooltip": "Webcam is ON", "class": ["active"]}'
else
    echo '{"text": "", "alt": "inactive", "tooltip": "Webcam is OFF", "class": ["inactive"]}'
fi

