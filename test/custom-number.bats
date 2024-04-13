#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../lib/custom-number.sh"
}

@test "Test digital format" {
  run custom_number '123' 'digital'
  [[ $output == "🯱🯲🯳" ]]
}

@test "Test fsquare format" {
  run custom_number '456' 'fsquare'
  [[ $output == "󰎭󰎱󰎳" ]]
}

@test "Test dsquare format" {
  run custom_number '789' 'dsquare'
  [[ $output == "󰎷󰎺󰎽" ]]
}

@test "Test hsquare format" {
  run custom_number '321' 'hsquare'
  [[ $output == "󰎬󰎩󰎦" ]]
}

@test "Test roman format" {
  run custom_number '5' 'roman'
  [[ $output == "󱂌" ]]
}

@test "Test super format" {
  run custom_number '678' 'super'
  [[ $output == "⁶⁷⁸" ]]
}

@test "Test sub format" {
  run custom_number '987' 'sub'
  [[ $output == "₉₈₇" ]]
}

@test "Test invalid format" {
  run custom_number '123' 'invalid'
  [[ $output == "123" ]]
}

@test "Test roman format with more than one digit" {
  run custom_number '12' 'roman'
  [[ $output == "12" ]]
}
