#!/usr/bin/env bash

# Check if enabled
ENABLED=$(tmux show-option -gv @tokyo-night-tmux_show_path 2>/dev/null)
[[ ${ENABLED} -ne 1 ]] && exit 0

# Imports
CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/path.sh
source "$CURRENT_DIR/../lib/path.sh"

PATH_FORMAT=$(tmux show-option -gv @tokyo-night-tmux_path_format 2>/dev/null) # full | relative
PATH_FORMAT="${PATH_FORMAT:-relative}"
RESET="#[fg=brightwhite,bg=#15161e,nobold,noitalics,nounderscore,nodim]"

current_path="${1}"

# check user requested format
if [[ ${PATH_FORMAT} == "relative" ]]; then
  current_path=$(relative_path "${current_path}")
fi

echo "#[fg=blue,bg=default]░  ${RESET}#[bg=default]${current_path} "
