#!/usr/bin/env bash

# Compatibility functions for macOS
if [[ "$(uname)" == "Darwin" ]]; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  # Use GNU coreutils if available
  if [ -d "$HOMEBREW_PREFIX/opt/coreutils" ]; then
    export PATH="$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH"
  fi
  # Use GNU awk if available
  if [ -d "$HOMEBREW_PREFIX/opt/gawk" ]; then
    export PATH="$HOMEBREW_PREFIX/opt/gawk/libexec/gnubin:$PATH"
  fi
  # Use GNU sed if available
  if [ -d "$HOMEBREW_PREFIX/opt/gsed" ]; then
    export PATH="$HOMEBREW_PREFIX/opt/gsed/libexec/gnubin:$PATH"
  fi
  # Use Homebrew bc if available
  if [ -d "$HOMEBREW_PREFIX/opt/bc" ]; then
    export PATH="$HOMEBREW_PREFIX/opt/bc/bin:$PATH"
  fi
fi

# Handle GNU date calls against BSD date
if ! date --version &>/dev/null; then
  real_date="$(which date)"
  echo "date: command not found" >&2

  function date() {
    local new_args=()

    while [ $# -gt 0 ]; do
      case "$1" in
      -d)
        shift
        if [[ $1 =~ ^@ ]]; then
          new_args+=("-r" "${1#@}")
        else
          new_args+=("-r" "$1")
        fi
        ;;
      *)
        new_args+=("$1")
        ;;
      esac
      shift
    done

    "$real_date" "${new_args[@]}"
  }
fi
