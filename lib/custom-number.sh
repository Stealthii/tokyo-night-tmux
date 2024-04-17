#!/usr/bin/env bash

# custom_number is a function that formats a given number into a specified format.
# It uses an associative array `format` to map digits to their corresponding format.
#
# Usage:
# custom_number <number> <format>
#
# Arguments:
# <number>: The number to be formatted. This should be a string of digits.
# <format>: The format to use. This should be a key in the `format` associative array.
#           Current supported formats are: digital, fsquare, dsquare, hsquare, roman, super, sub.
#
# Returns:
# The function prints the formatted number to stdout. If an invalid format is provided,
# the function prints the original number. For the 'roman' format, only single digit numbers are supported.
#
# Example:
# custom_number "1337" "digital"
# This will output: "🯱🯳🯳🯷"

function custom_number() {
  declare -A format

  # digital: 🯰🯱🯲🯳🯴🯵🯶🯷🯸🯹
  format[digital]="\U0001fbf0 \U0001fbf1 \U0001fbf2 \U0001fbf3 \U0001fbf4 \U0001fbf5 \U0001fbf6 \U0001fbf7 \U0001fbf8 \U0001fbf9"
  # fsquare: 󰎡󰎤󰎧󰎪󰎭󰎱󰎳󰎶󰎹󰎼
  format[fsquare]="\U000f03a1 \U000f03a4 \U000f03a7 \U000f03aa \U000f03ad \U000f03b1 \U000f03b3 \U000f03b6 \U000f03b9 \U000f03bc"
  # dsquare: 󰎢󰎥󰎨󰎫󰎲󰎯󰎴󰎷󰎺󰎽
  format[dsquare]="\U000f03a2 \U000f03a5 \U000f03a8 \U000f03ab \U000f03b2 \U000f03af \U000f03b4 \U000f03b7 \U000f03ba \U000f03bd"
  # hsquare: 󰎣󰎦󰎩󰎬󰎮󰎰󰎵󰎸󰎻󰎾
  format[hsquare]="\U000f03a3 \U000f03a6 \U000f03a9 \U000f03ac \U000f03ae \U000f03b0 \U000f03b5 \U000f03b8 \U000f03bb \U000f03be"
  # roman:  󱂈󱂉󱂊󱂋󱂌󱂍󱂎󱂏󱂐
  format[roman]="\u0020 \U000f1088 \U000f1089 \U000f108a \U000f108b \U000f108c \U000f108d \U000f108e \U000f108f \U000f1090"
  # super: ⁰¹²³⁴⁵⁶⁷⁸⁹
  format[super]="\u2070 \u00b9 \u00b2 \u00b3 \u2074 \u2075 \u2076 \u2077 \u2078 \u2079"
  # sub: ₀₁₂₃₄₅₆₇₈₉
  format[sub]="\u2080 \u2081 \u2082 \u2083 \u2084 \u2085 \u2086 \u2087 \u2088 \u2089"

  local ID=$1
  local FORMAT=$2
  IFS=" " read -r -a sformat <<<"${format[$FORMAT]}"
  if [ -z "${sformat[1]}" ]; then
    # Invalid or no format specified
    echo -n "$ID"
  # If format is roman numerals (-r), only handle IDs of 1 digit
  elif [ "$FORMAT" = "roman" ] && [ ${#ID} -gt 1 ]; then
    echo -n "$ID"
  else
    for ((i = 0; i < ${#ID}; i++)); do
      DIGIT=${ID:i:1}
      echo -ne "${sformat[$DIGIT]}"
    done
  fi
}
