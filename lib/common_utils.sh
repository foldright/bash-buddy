#!/bin/bash
#
# common util functions.
# use short namespace `cu`, since these functions will be used frequent.
#
#_ source guard start _#
[ -z "${__source_guard_B016CBE5_CBB5_4AF4_BE46_ECA9FD30BACA:+has_value}" ] || return 0
__source_guard_B016CBE5_CBB5_4AF4_BE46_ECA9FD30BACA="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly __source_guard_B016CBE5_CBB5_4AF4_BE46_ECA9FD30BACA
#_ source guard end _#

set -eEuo pipefail

################################################################################
# simple color print functions
################################################################################

cu::color_echo() {
  local color=$1
  shift

  # NOTE: $'foo' is the escape sequence syntax of bash
  local -r ec=$'\033'      # escape char
  local -r eend=$'\033[0m' # escape end

  # if stdout is the console, turn on color output.
  [ -t 1 ] && echo "${ec}[1;${color}m$*${eend}" || echo "$*"
}

cu::red_echo() {
  cu::color_echo 31 "$@"
}

cu::yellow_echo() {
  cu::color_echo 33 "$@"
}

cu::blue_echo() {
  cu::color_echo 36 "$@"
}

cu::head_line_echo() {
  cu::color_echo "2;35;46" ================================================================================
  cu::yellow_echo "$*"
  cu::color_echo "2;35;46" ================================================================================
}

################################################################################
# validation functions
################################################################################

cu::is_number_string() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  [[ "$1" =~ ^[0-9]+$ ]]
}

################################################################################
# version comparison functions
#
# How to compare a program's version in a shell script?
#   https://unix.stackexchange.com/questions/285924
################################################################################

# cu::version_ge <version1> <version2>
# version1 is greater than or equal to version2
cu::version_ge() {
  (($# == 2)) || cu::die "${FUNCNAME[0]} requires exact 2 arguments! But provided $#: $*"

  local ver=$1
  local destVer=$2

  [ "$ver" = "$destVer" ] && return 0

  [ "$(printf '%s\n' "$ver" "$destVer" | sort -V | head -n1)" = "$destVer" ]
}

# cu::version_lt <version1> <version2>
# version1 is less than version2
cu::version_lt() {
  (($# == 2)) || cu::die "${FUNCNAME[0]} requires exact 2 arguments! But provided $#: $*"

  local ver=$1
  local destVer=$2

  [ "$ver" = "$destVer" ] && return 1

  [ "$(printf '%s\n' "$ver" "$destVer" | sort -V | head -n1)" = "$ver" ]
}

cu::_get_first_match_version() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local version_pattern="$1" ver
  while read -r ver; do
    if [[ "$ver" == "$version_pattern" || "$ver" == "${version_pattern}"[.-]* ]]; then
      echo "$ver"
      # drain the rest content of stdin
      cat >/dev/null
      return
    fi
  done
}

# get the latest version of versions(one version per line) from stdin
#
# sort versions by command `sort -V`
cu::get_latest_version() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local -r version_pattern="$1"
  sort -V -r | cu::_get_first_match_version "$version_pattern"
}

################################################################################
# execution helper functions
################################################################################

cu::loose_run() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  set +eEuo pipefail
  "$@"
  local exit_code=$?
  set -eEuo pipefail
  return $exit_code
}

cu::log_then_run() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  local simple_mode=false
  [ "$1" = "-s" ] && {
    simple_mode=true
    shift
  }

  if $simple_mode; then
    echo "Run under work directory $PWD : $*" >&2
    "$@"
  else
    cu::blue_echo "Run under work directory $PWD :" >&2
    cu::blue_echo "$*" >&2
    time "$@"
  fi
}

cu::die() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  cu::red_echo "Error: $*" >&2
  exit 1
}
