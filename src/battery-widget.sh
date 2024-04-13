#!/usr/bin/env bash

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_battery_widget 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
source "$ROOT_DIR/src/themes.sh"
source "$ROOT_DIR/lib/battery.sh"

# Default battery name is auto-determined
BATTERY_NAME=$(tmux show-option -gv @tokyo-night-tmux_battery_name 2>/dev/null)
# Default battery low threshold is 20%
BATTERY_LOW=$(tmux show-option -gv @tokyo-night-tmux_battery_low_threshold 2>/dev/null)
BATTERY_LOW=${BATTERY_LOW:-20}

DISCHARGING_ICONS=("󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹")
CHARGING_ICONS=("󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅")
NOT_CHARGING_ICON="󰚥"
NO_BATTERY_ICON="󱉝"

# get battery stats
BATTERY_STATUS=$(battery status "$BATTERY_NAME")
BATTERY_PERCENTAGE=$(battery percentage "$BATTERY_NAME")

# set color and icon based on battery status
COLOR="#[fg=${THEME[yellow]},bg=${THEME[background]}]" # default color
case "${BATTERY_STATUS}" in
"Charging" | "charging" | "finishing charge")
  ICONS="${CHARGING_ICONS[$((BATTERY_PERCENTAGE / 10 - 1))]}"
  ;;
"Discharging" | "discharging")
  ICONS="${DISCHARGING_ICONS[$((BATTERY_PERCENTAGE / 10 - 1))]}"
  # Red if battery is low
  [[ ${BATTERY_PERCENTAGE} -le ${BATTERY_LOW} ]] && COLOR="#[fg=${THEME[red]},bg=${THEME[background]},bold]"
  ;;
"Not charging" | "AC attached")
  ICONS="${NOT_CHARGING_ICON}"
  ;;
"Full" | "charged")
  ICONS="${NOT_CHARGING_ICON}"
  COLOR="#[fg=${THEME[green]},bg=${THEME[background]}]"
  ;;
*)
  ICONS="${NO_BATTERY_ICON}"
  ;;
esac

echo "${COLOR}░ ${ICONS}${RESET} ${BATTERY_PERCENTAGE}% "
