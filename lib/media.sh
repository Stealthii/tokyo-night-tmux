#!/usr/bin/env bash

# Imports
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/coreutils-compat.sh
source "$CURRENT_DIR/coreutils-compat.sh"

export MEDIA_METADATA_PROPERTIES=(status artist title elapsed duration progress)
declare -gA MEDIA_METADATA

function media_metadata_playerctl() {
  # Get metadata
  PLAYERCTL_PROPERTIES=(status artist title length position)
  mapfile -t PLAYERCTL_OUTPUT < <(playerctl --player=%any,chromium,chrome,firefox metadata --format "{{lc(status)}}\n{{artist}}\n{{title}}\n{{mpris:length}}\n{{mpris:position}}" 2>/dev/null)
  declare -A PLAYERCTL_VALUES
  for ((i = 0; i < ${#PLAYERCTL_PROPERTIES[@]}; i++)); do
    PLAYERCTL_VALUES[${PLAYERCTL_PROPERTIES[i]}]=${PLAYERCTL_OUTPUT[i]}
  done

  # Status, Artist and Title
  MEDIA_METADATA[status]="${PLAYERCTL_VALUES[status]}"
  MEDIA_METADATA[artist]="${PLAYERCTL_VALUES[artist]}"
  MEDIA_METADATA[title]="${PLAYERCTL_VALUES[title]}"

  # Calculate elapsed time, duration, and progress
  MEDIA_METADATA[elapsed]=$(printf "%.0f" "$(bc -l <<<"(${PLAYERCTL_VALUES[position]} / 1000000")")
  MEDIA_METADATA[duration]=$(printf "%.0f" "$(bc -l <<<"(${PLAYERCTL_VALUES[length]} / 1000000")")
  if [[ ${MEDIA_METADATA[duration]} -eq 0 ]]; then
    MEDIA_METADATA[progress]=100
  else
    # Use bc to calculate progress percentage
    MEDIA_METADATA[progress]=$(printf "%.0f" "$(bc -l <<<"(${PLAYERCTL_VALUES[position]} / ${PLAYERCTL_VALUES[length]}) * 100")")
  fi
}

function media_metadata_nowplaying() {
  NPCLI_PROPERTIES=(artist title duration elapsedTime playbackRate isAlwaysLive)
  mapfile -t NPCLI_OUTPUT < <(nowplaying-cli get "${NPCLI_PROPERTIES[@]}")
  declare -A NPCLI_VALUES
  for ((i = 0; i < ${#NPCLI_PROPERTIES[@]}; i++)); do
    # Handle null values
    [[ ${NPCLI_OUTPUT[i]} == null ]] && NPCLI_OUTPUT[i]=''
    NPCLI_VALUES[${NPCLI_PROPERTIES[i]}]=${NPCLI_OUTPUT[i]}
  done

  # Artist and title
  MEDIA_METADATA[artist]="${NPCLI_VALUES[artist]}"
  MEDIA_METADATA[title]="${NPCLI_VALUES[title]}"

  # Calculate playback status
  if [[ -n ${NPCLI_VALUES[playbackRate]} ]] && [[ ${NPCLI_VALUES[playbackRate]} -gt 0 ]]; then
    MEDIA_METADATA[status]="playing"
  else
    MEDIA_METADATA[status]="paused"
  fi

  # Calculate elapsed time, duration, and progress
  MEDIA_METADATA[elapsed]=$(printf "%.0f" "${NPCLI_VALUES[elapsedTime]}")
  MEDIA_METADATA[duration]=$(printf "%.0f" "${NPCLI_VALUES[duration]}")
  if [[ ${NPCLI_VALUES[isAlwaysLive]} -ne 0 ]]; then
    MEDIA_METADATA[duration]="${MEDIA_METADATA[elapsed]}"
  fi
  if [[ ${MEDIA_METADATA[duration]} -eq 0 ]]; then
    MEDIA_METADATA[progress]=100
  else
    # Use bc to calculate progress percentage
    MEDIA_METADATA[progress]=$(printf "%.0f" "$(bc -l <<<"(${NPCLI_VALUES[elapsedTime]} / ${NPCLI_VALUES[duration]}) * 100")")
  fi
}

function media_metadata_update() {
  # macOS metadata
  if command -v nowplaying-cli >/dev/null; then
    media_metadata_nowplaying
  # playerctl metadata
  elif command -v playerctl >/dev/null; then
    media_metadata_playerctl
  # Empty metadata
  else
    for property in "${MEDIA_METADATA_PROPERTIES[@]}"; do
      MEDIA_METADATA[$property]=""
    done
  fi
}

function media_metadata_print() {
  # Echo metadata as newline-separated list
  for property in "${MEDIA_METADATA_PROPERTIES[@]}"; do
    echo "${MEDIA_METADATA[$property]}"
  done
}

function media_metadata_timestamp() {
  # Nothing if no duration
  [[ -z ${MEDIA_METADATA[duration]} ]] && echo "[--:--]" && return

  # Calculate remaining time
  local remaining=$((MEDIA_METADATA[duration] - MEDIA_METADATA[elapsed]))
  if [[ $remaining -lt 3600 ]]; then
    remaining="$(date -d "@$remaining" -u +%M:%S)"
  elif [[ $remaining -lt 86400 ]]; then
    remaining="$(date -d "@$remaining" -u +%H:%M:%S)"
  else
    # If over 1 day, just show ">1d"
    echo "[>1d]"
    return
  fi

  # Calculate elapsed and duration timestamps
  local elapsed duration
  if [[ ${MEDIA_METADATA[duration]} -lt 3600 ]]; then
    elapsed="$(date -d "@${MEDIA_METADATA[elapsed]}" -u +%M:%S)"
    duration="$(date -d "@${MEDIA_METADATA[duration]}" -u +%M:%S)"
  elif [[ ${MEDIA_METADATA[duration]} -lt 86400 ]]; then
    elapsed="$(date -d "@${MEDIA_METADATA[elapsed]}" -u +%H:%M:%S)"
    duration="$(date -d "@${MEDIA_METADATA[duration]}" -u +%H:%M:%S)"
  else
    echo "[>1d]"
    return
  fi

  # Drop one leading zero if present
  elapsed="${elapsed#0}"
  duration="${duration#0}"
  remaining="${remaining#0}"

  # Determine format
  local format="$1"
  case $format in
  elapsed)
    echo "[$elapsed]"
    ;;
  remaining)
    echo "[-$remaining]"
    ;;
  *) # full by default
    echo "[$elapsed / $duration]"
    ;;
  esac
}

function media_metadata() {
  case $1 in
  update | refresh | fetch)
    media_metadata_update
    ;;
  print)
    media_metadata_print
    ;;
  timestamp)
    media_metadata_timestamp "$2"
    ;;
  *)
    # if property, print that
    for property in "${MEDIA_METADATA_PROPERTIES[@]}"; do
      if [[ $1 == "$property" ]]; then
        echo "${MEDIA_METADATA[$property]}"
        return
      fi
    done

    # Do update and print by default
    media_metadata_update
    media_metadata_print
    ;;
  esac
}
