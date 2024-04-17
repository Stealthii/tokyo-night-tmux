#!/usr/bin/env bats

setup() {
  # shellcheck source=lib/path.sh
  source "${BATS_TEST_DIRNAME}/../lib/path.sh"
}

@test "Test relative path" {
  example_path="${HOME}/example"
  run relative_path "${example_path}"
  [[ $status -eq 0 ]]
  # shellcheck disable=SC2088
  [[ $output == "~/example" ]]
}
