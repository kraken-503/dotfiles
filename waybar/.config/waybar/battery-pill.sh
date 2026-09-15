#!/bin/bash

BATTERY="/sys/class/power_supply/BAT1"

capacity=$(cat "$BATTERY/capacity")
status=$(cat "$BATTERY/status")

# Choose battery state
if [ "$capacity" -gt 55 ]; then
    state="good"
elif [ "$capacity" -ge 25 ]; then
    state="warning"
else
    state="critical"
fi

# Add charging state
if [ "$status" = "Charging" ]; then
    state="$state charging"
fi

printf '{"text":"%s%%","class":"battery-%s %s","percentage":%s,"tooltip":"Battery: %s%%\\nStatus: %s"}\n' \
    "$capacity" \
    "$capacity" \
    "$state" \
    "$capacity" \
    "$capacity" \
    "$status"

