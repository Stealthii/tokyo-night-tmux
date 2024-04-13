#!/usr/bin/env bats

setup() {
  if [[ $(uname) == "Darwin" ]]; then
    HOMEBREW_PREFIX=$(brew --prefix)
    load "${HOMEBREW_PREFIX}/lib/bats-mock/stub.bash"
  else
    skip "macOS only tests"
  fi
  source "${BATS_TEST_DIRNAME}/../lib/battery.sh"

  # pmset battery stats: discharging, charging, AC attached, finishing charge, charged
  stub pmset \
    "-g batt : echo -e \"Now drawing from 'Battery Power'\n -InternalBattery-0 (id=12345678)       87%; discharging; 4:47 remaining present: true\n\"" \
    "-g batt : echo -e \"Now drawing from 'AC Power'\n -InternalBattery-0 (id=12345678)       78%; charging; 0:39 remaining present: true\n\"" \
    "-g batt : echo -e \"Now drawing from 'AC Power'\n -InternalBattery-0 (id=12345678)       90%; AC attached; not charging present: true\n\"" \
    "-g batt : echo -e \"Now drawing from 'AC Power'\n -InternalBattery-0 (id=12345678)       100%; finishing charge; 0:06 remaining present: true\n\"" \
    "-g batt : echo -e \"Now drawing from 'AC Power'\n -InternalBattery-0 (id=12345678)       100%; charged; 0:00 remaining present: true\n\""
}

teardown() {
  if [[ $(uname) == "Darwin" ]]; then
    run unstub pmset
  fi
}

@test "Test macOS battery status" {
  run battery status
  [[ $output == "discharging" ]]
  run battery status
  [[ $output == "charging" ]]
  run battery status
  [[ $output == "AC attached" ]]
  run battery status
  [[ $output == "finishing charge" ]]
  run battery status
  [[ $output == "charged" ]]
}

@test "Test macOS battery percentage" {
  run battery percentage
  [[ $output -eq 87 ]]
  run battery percentage
  [[ $output -eq 78 ]]
  run battery percentage
  [[ $output -eq 90 ]]
  run battery percentage
  [[ $output -eq 100 ]]
  run battery percentage
  [[ $output -eq 100 ]]
}
