#!/bin/bash
#
# common util functions.
# use short namespace `cu`, since these functions will be used frequent.
#
################################################################################
# api functions:
#  - simple color print functions:
#   - cu::red_echo
#   - cu::yellow_echo
#   - cu::blue_echo
#   - cu::head_line_echo
#  - validation functions:
#   - cu::is_number_string
#   - cu::is_blank_string
#  - version related functions
#   - cu::version_le
#   - cu::version_lt
#   - cu::version_ge
#   - cu::version_gt
#   - cu::is_version_match
#   - cu::get_latest_version_match
#   - cu::get_oldest_version_match
#  - execution helper functions:
#   - cu::log_then_run
#   - cu::loose_run
#   - cu::die
################################################################################
#
#_ source guard begin _#
[ -n "${source_guard_B016CBE5_CBB5_4AF4_BE46_ECA9FD30BACA:+has_value}" ] && return
source_guard_B016CBE5_CBB5_4AF4_BE46_ECA9FD30BACA=$(realpath -- "${BASH_SOURCE[0]}")
# the value of source guard is the canonical dir path of this script
readonly source_guard_B016CBE5_CBB5_4AF4_BE46_ECA9FD30BACA=${source_guard_B016CBE5_CBB5_4AF4_BE46_ECA9FD30BACA%/*}
#_ source guard end _#

set -eEuo pipefail

################################################################################
# simple color print functions
################################################################################

cu::color_echo() {
  local color=$1
  shift

  # if stdout is terminal, turn on color output.
  #
  # about CI env var
  #   https://docs.github.com/en/actions/learn-github-actions/variables#default-environment-variables
  if [[ -t 1 || "${GITHUB_ACTIONS:-}" = true ]]; then
    printf "\e[1;${color}m%s\e[0m\n" "$*"
  else
    printf '%s\n' "$*"
  fi
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

cu::is_blank_string() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  [[ "$1" =~ ^[[:space:]]*$ ]]
}

################################################################################
# version related functions
#
# versions comparison/sort by command `sort -V`
#
# How to compare a program's version in a shell script?
#   https://unix.stackexchange.com/questions/285924
################################################################################

# version comparison, is version1 less than or equal to version2?
#
# usage:
# cu::version_le <version1> <version2>
cu::version_le() {
  (($# == 2)) || cu::die "${FUNCNAME[0]} requires exact 2 arguments! But provided $#: $*"

  local ver=$1
  local destVer=$2

  [ "$ver" = "$destVer" ] && return 0

  [ "$(printf '%s\n' "$ver" "$destVer" | sort -V | head -n1)" = "$ver" ]
}

# version comparison, is version1 less than version2?
#
# usage:
# cu::version_lt <version1> <version2>
cu::version_lt() {
  (($# == 2)) || cu::die "${FUNCNAME[0]} requires exact 2 arguments! But provided $#: $*"

  local ver=$1
  local destVer=$2

  [ "$ver" = "$destVer" ] && return 1

  [ "$(printf '%s\n' "$ver" "$destVer" | sort -V | head -n1)" = "$ver" ]
}

# version comparison, is version1 greater than or equal to version2?
#
# usage:
# cu::version_ge <version1> <version2>
cu::version_ge() {
  (($# == 2)) || cu::die "${FUNCNAME[0]} requires exact 2 arguments! But provided $#: $*"

  local ver=$1
  local destVer=$2

  [ "$ver" = "$destVer" ] && return 0

  [ "$(printf '%s\n' "$ver" "$destVer" | sort -V | head -n1)" = "$destVer" ]
}

# version comparison, is version1 greater than version2?
#
# usage:
# cu::version_gt <version1> <version2>
cu::version_gt() {
  (($# == 2)) || cu::die "${FUNCNAME[0]} requires exact 2 arguments! But provided $#: $*"

  local ver=$1
  local destVer=$2

  [ "$ver" = "$destVer" ] && return 1

  [ "$(printf '%s\n' "$ver" "$destVer" | sort -V | head -n1)" = "$destVer" ]
}

# version match, is version match version pattern?
#
# usage:
# cu::version_gt <version> <version pattern>
#
# example:
#   cu::is_version_match 11.0.1-p1 11         # true
#   cu::is_version_match 11.0.1-p1 11.0       # true
#   cu::is_version_match 11.0.1-p1 11.0.1     # true
#   cu::is_version_match 11.0.1-p1 11.0.1-p1  # true
#
#   cu::is_version_match 11.0.1-p1 10         # false
#   cu::is_version_match 11.0.1-p1 12         # false
#   cu::is_version_match 11.0.1-p1 11.1       # false
#   cu::is_version_match 11.0.1-p1 11.0.0     # false
#   cu::is_version_match 11.0.1-p1 11.0.1-rc  # false
cu::is_version_match() {
  (($# == 2)) || cu::die "${FUNCNAME[0]} requires exact 2 arguments! But provided $#: $*"

  local ver="$1" version_pattern="$2"
  [[ "$ver" == "$version_pattern" || "$ver" == "$version_pattern"[.-]* ]]
}

cu::_get_first_version_match() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local version_pattern="$1" ver
  while read -r ver; do
    if cu::is_version_match "$ver" "$version_pattern"; then
      echo "$ver"
      # drain the rest content of stdin
      cat >/dev/null
      return
    fi
  done
}

# get the latest version of versions(one version per line) from stdin
#
# usage:
# cu::get_latest_version_match <version pattern>
cu::get_latest_version_match() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local -r version_pattern="$1"
  sort -V -r | cu::_get_first_version_match "$version_pattern"
}

# get the oldest version of versions(one version per line) from stdin
#
# usage:
# cu::get_oldest_version_match <version pattern>
cu::get_oldest_version_match() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local -r version_pattern="$1"
  sort -V | cu::_get_first_version_match "$version_pattern"
}

################################################################################
# execution helper functions
################################################################################

# log the command line, then run it.
#
# usage:
#   cu::log_then_run command_to_run command_args...
#
# example:
#   cu::log_then_run echo hello world
cu::log_then_run() {
  local simple_mode=false
  [ "$1" = "-s" ] && {
    simple_mode=true
    shift
  }

  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  if $simple_mode; then
    echo "Run under work directory $PWD : $(cu::print_calling_command_line "$@")" >&2
    "$@"
  else
    cu::blue_echo "Run under work directory $PWD :" >&2
    cu::blue_echo "$(cu::print_calling_command_line "$@")" >&2
    time "$@"
  fi
}

cu::loose_run() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  set +eEuo pipefail
  "$@"
  local exit_code=$?
  set -eEuo pipefail
  return $exit_code
}

# print calling(quoted) command line which is able to copy and paste to rerun safely
#
# How to get the complete calling command of a BASH script from inside the script (not just the arguments)
# https://stackoverflow.com/questions/36625593
#
# bash metacharacter:
# https://www.gnu.org/software/bash/manual/html_node/Definitions.html
cu::print_calling_command_line() {
  local arg isFirst=true bash_meta_char_regex=$'[ \t\n|&;()<>$!"]'

  for arg; do
    if $isFirst; then
      isFirst=false
    else
      printf ' '
    fi

    if [[ "$arg" =~ \' ]]; then
      printf '%q' "$arg"
    elif [[ "$arg" =~ $bash_meta_char_regex ]]; then
      printf "'%s'" "$arg"
    else
      printf "%s" "$arg"
    fi
  done
  echo
}

# output the error message then exit with error(exit code is 1)
cu::die() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  cu::red_echo "Error: $*" >&2
  exit 1
}
