#!/usr/bin/env bash

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/battery.sh"

# check if not enabled
SHOW_BATTERY_WIDGET=$(tmux show-option -gv @tokyo-night-tmux_show_battery_widget 2>/dev/null)
if [ "${SHOW_BATTERY_WIDGET}" != "1" ]; then
  exit 0
fi

# Default battery name is auto-determined
BATTERY_NAME=$(tmux show-option -gv @tokyo-night-tmux_battery_name 2>/dev/null)
# Default battery low threshold is 21%
BATTERY_LOW=$(tmux show-option -gv @tokyo-night-tmux_battery_low_threshold 2>/dev/null)
BATTERY_LOW=${BATTERY_LOW:-21}
RESET="#[fg=brightwhite,bg=#15161e,nobold,noitalics,nounderscore,nodim]"

DISCHARGING_ICONS=("󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
CHARGING_ICONS=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
NOT_CHARGING_ICON="󰚥"
NO_BATTERY_ICON="󱉝"

# get battery stats
BATTERY_STATUS=$(battery status "$BATTERY_NAME")
BATTERY_PERCENTAGE=$(battery percentage "$BATTERY_NAME")

# set color and icon based on battery status
case "${BATTERY_STATUS}" in
"Charging" | "charging" | "finishing charge")
  ICONS="${CHARGING_ICONS[$((BATTERY_PERCENTAGE / 10 - 1))]}"
  ;;
"Discharging" | "discharging")
  ICONS="${DISCHARGING_ICONS[$((BATTERY_PERCENTAGE / 10 - 1))]}"
  ;;
"Not charging" | "AC attached")
  ICONS="${NOT_CHARGING_ICON}"
  ;;
"Full" | "charged")
  ICONS="${NOT_CHARGING_ICON}"
  ;;
*)
  ICONS="${NO_BATTERY_ICON}"
  ;;
esac

# set color on battery capacity
if [[ ${BATTERY_PERCENTAGE} -lt ${BATTERY_LOW} ]]; then
  _color="#[fg=red,bg=default,bold]"
elif [[ ${BATTERY_PERCENTAGE} -ge 100 ]]; then
  _color="#[fg=green,bg=default]"
else
  _color="#[fg=yellow,bg=default]"
fi

echo "${_color}░ ${ICONS}${RESET}#[bg=default] ${BATTERY_PERCENTAGE}% "
