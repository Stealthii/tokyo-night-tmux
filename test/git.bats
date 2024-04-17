#!/usr/bin/env bats

setup() {
  if [[ $(uname) == "Darwin" ]]; then
    HOMEBREW_PREFIX=$(brew --prefix)
    load "${HOMEBREW_PREFIX}/lib/bats-mock/stub.bash"
  else
    load /usr/lib/bats-mock/stub.bash
  fi
  source "${BATS_TEST_DIRNAME}/../lib/git.sh"

  # pmset battery stats: discharging, charging, AC attached, finishing charge, charged
  stub git \
    "remote get-url origin : echo 'https://github.com/Stealthii/tokyo-night-tmux.git'" \
    "remote get-url origin : echo 'git@gitlab.com:inkscape/inkscape.git'" \
    "remote get-url origin : echo 'ssh://git@stash.corp.company.org:7999/team/tokyo-night-tmux.git'"
}

teardown() {
  run unstub git
}

@test "Test get_provider" {
  run get_provider
  [[ $output == "github.com" ]]
  run get_provider
  [[ $output == "gitlab.com" ]]
  run get_provider
  [[ $output == "stash.corp.company.org" ]]
}
