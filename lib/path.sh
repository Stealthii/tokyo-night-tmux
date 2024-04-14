#!/usr/bin/env bash

function relative_path() {
  current_path="${1/#$HOME/\\x7e}"
  echo -e "${current_path}"
}
