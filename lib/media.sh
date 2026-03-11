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
  local mc_json
  mc_json=$(media-control get --now 2>/dev/null) || return

  # Parse JSON with jq
  local mc_artist mc_title mc_duration mc_elapsed mc_playback_rate mc_playing
  mc_artist=$(jq -r '.artist // empty' <<<"$mc_json")
  mc_title=$(jq -r '.title // empty' <<<"$mc_json")
  mc_duration=$(jq -r '.duration // 0' <<<"$mc_json")
  mc_elapsed=$(jq -r '.elapsedTimeNow // .elapsedTime // 0' <<<"$mc_json")
  mc_playback_rate=$(jq -r '.playbackRate // 0' <<<"$mc_json")
  mc_playing=$(jq -r '.playing // false' <<<"$mc_json")

  # Artist and title
  MEDIA_METADATA[artist]="$mc_artist"
  MEDIA_METADATA[title]="$mc_title"

  # Calculate playback status
  if [[ $mc_playing == "true" ]] || { [[ -n $mc_playback_rate ]] && [[ $mc_playback_rate -gt 0 ]]; }; then
    MEDIA_METADATA[status]="playing"
  else
    MEDIA_METADATA[status]="paused"
  fi

  # Calculate elapsed time, duration, and progress
  MEDIA_METADATA[elapsed]=$(printf "%.0f" "$mc_elapsed")
  MEDIA_METADATA[duration]=$(printf "%.0f" "$mc_duration")
  if [[ ${MEDIA_METADATA[duration]} -eq 0 ]]; then
    MEDIA_METADATA[progress]=100
  else
    # Use bc to calculate progress percentage
    MEDIA_METADATA[progress]=$(printf "%.0f" "$(bc -l <<<"($mc_elapsed / $mc_duration) * 100")")
  fi
}

function media_metadata_update() {
  # macOS metadata
  if command -v media-control >/dev/null; then
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
