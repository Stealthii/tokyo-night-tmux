#!/usr/bin/env bash

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_music 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

# Imports
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=src/themes.sh
source "$CURRENT_DIR/themes.sh"
# shellcheck source=lib/media.sh
source "$CURRENT_DIR/../lib/media.sh"
# shellcheck source=lib/custom-number.sh
source "$CURRENT_DIR/../lib/custom-number.sh"

# Get max length from tmux config
MAX_LENGTH=$(tmux show -gv @tokyo-night-tmux_music_maxsize 2>/dev/null)
# Default to 20% of the window width
[[ -z $MAX_LENGTH ]] && MAX_LENGTH="20%"
# If MAX_LENGTH ends in %, calculate the percentage of the window width
[[ $MAX_LENGTH == *% ]] && MAX_LENGTH=$(($(tmux display -p '#{window_width}' 2>/dev/null || echo 120) * ${MAX_LENGTH%\%} / 100))

# Fetch metadata
media_metadata update

# Exit if no metadata is available
[[ -z ${MEDIA_METADATA[*]} ]] && exit 0

# Generate output
declare -a D_OUTPUT=("░")

# Playstate
D_OUTPUT[1]=$([[ ${MEDIA_METADATA[status]} == playing ]] && echo "" || echo "󰏤")

# Artist & Title
ARTIST="${MEDIA_METADATA[artist]}"
TITLE="${MEDIA_METADATA[title]}"
D_OUTPUT[2]="${ARTIST:+$ARTIST - }${TITLE}"

# Time
D_OUTPUT[3]="$(media_metadata timestamp full)"

# Initial output
OUTPUT="${D_OUTPUT[*]}"

# Adjust output based on max length
if [[ ${#OUTPUT} -ge $MAX_LENGTH ]]; then
  # Drop to remaining time
  D_OUTPUT[3]=$(media_metadata timestamp remaining)
  OUTPUT="${D_OUTPUT[*]}"
fi
if [[ ${#OUTPUT} -ge $MAX_LENGTH ]]; then
  # Drop artist
  D_OUTPUT[2]="$TITLE"
  OUTPUT="${D_OUTPUT[*]}"
fi
if [[ ${#OUTPUT} -ge $MAX_LENGTH ]]; then
  # Trim title to fit total max length
  D_OUTPUT[2]="${TITLE:0:$MAX_LENGTH-${#OUTPUT}+${#TITLE}}…"
  OUTPUT="${D_OUTPUT[*]}"
fi

# Styling
ACCENT_COLOR="${THEME[blue]}"
BG_COLOR="${THEME[background]}"
TIME_COLOR="${THEME[black]}"
[[ ${MEDIA_METADATA[status]} == playing ]] && BAR_COLOR="${THEME[bgreen]}" || BAR_COLOR="${THEME[bwhite]}"
STYLE=$(tmux show -gv @tokyo-night-tmux_music_style 2>/dev/null)

if [[ $STYLE == "colorscore" ]]; then
  L_BAR="${D_OUTPUT[0]} ${D_OUTPUT[1]}"
  R_BAR="${D_OUTPUT[2]} ${D_OUTPUT[3]}"
  R_LEN=${#R_BAR}
  PROG_IDX=$((MEDIA_METADATA[progress] * R_LEN / 100))
  TIME_IDX=$((${#D_OUTPUT[2]} + 1))

  echo -n "#[nobold,fg=$ACCENT_COLOR,bg=$BG_COLOR,us=$BAR_COLOR]${L_BAR} #[double-underscore,underscore]"
  for ((i = 0; i < R_LEN; i++)); do
    CHAR="${R_BAR:i:1}"
    [[ $i -eq $TIME_IDX ]] && echo -n "#[fg=$TIME_COLOR]"
    [[ $((i - 1)) -eq $PROG_IDX ]] && echo -n "#[nodouble-underscore]"
    [[ $i -eq $PROG_IDX ]] && echo -n "#[nounderscore]"
    [[ $i -ge $TIME_IDX ]] && [[ $CHAR =~ ^[0-9]+$ ]] && echo -n "$(custom_number "$CHAR" digital)" || echo -n "${CHAR}"
  done
  echo "$RESET#[nounderscore,nodouble-underscore] "
# Default bar style
else
  # Calculate progress index
  PROG_IDX=$((${#OUTPUT} * MEDIA_METADATA[progress] / 100))
  # Calculate timestamp index
  TIME_IDX=$((${#D_OUTPUT[0]} + ${#D_OUTPUT[1]} + ${#D_OUTPUT[2]} + 2))
  # Positive distance between progress and timestamp
  PROG_TIME_LEN=$((TIME_IDX - PROG_IDX))
  [[ $PROG_TIME_LEN -lt 0 ]] && PROG_TIME_LEN=0 && TIME_IDX=$PROG_IDX

  echo "#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${OUTPUT:0:PROG_IDX}#[fg=$ACCENT_COLOR,bg=$BG_COLOR]${OUTPUT:PROG_IDX:PROG_TIME_LEN}#[fg=$TIME_COLOR,bg=$BG_COLOR]${OUTPUT:TIME_IDX} "
fi
