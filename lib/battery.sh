#!/usr/bin/env bash

function battery() {
  local request=${1:-percentage}
  local battery_name=${2}

  # if battery name is not provided, calculate it based on the OS
  if [ -z "$battery_name" ]; then
    if [[ "$(uname)" == "Darwin" ]]; then
      battery_name="InternalBattery-0"
    # Get the last battery in the list if it exists
    elif [[ -d /sys/class/power_supply ]]; then
      battery_name=$(find /sys/class/power_supply/ -name "BAT*" -print | tail -n 1)
    fi
  fi

  # Get battery stats from pmset for macOS
  if [[ "$(uname)" == "Darwin" ]]; then
    pmstat=$(pmset -g batt | grep "$battery_name")
    battery_status=$(echo "$pmstat" | awk -F\; '{print substr( $2, 2)}')
    battery_percentage=$(echo "$pmstat" | awk -F'[^0-9]*' '{print $4}')
  # Get battery stats from sysfs
  elif [[ -n $battery_name ]]; then
    battery_status=$(</sys/class/power_supply/"${battery_name}"/status)
    battery_percentage=$(</sys/class/power_supply/"${battery_name}"/capacity)
  # Default if no battery is found
  else
    battery_status=""
    battery_percentage="0"
  fi

  case "$request" in
  percentage)
    echo "$battery_percentage"
    ;;
  status)
    echo "$battery_status"
    ;;
  *)
    echo "Invalid request: $request"
    return 1
    ;;
  esac
}
