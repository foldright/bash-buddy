#!/bin/bash
#
# a common lib to show trapped error info.
#
# provide function `trap_error_info::register_show_error_info_handler` to register
# the error-trap handler which show error info when trapped error.
#
# by default, auto call `trap_error_info::register_show_error_info_handler` when source this script;
# disable by define `TRAP_ERROR_NO_AUTO_REGISTER` var
#
################################################################################
# api functions:
#   - trap_error_info::register_show_error_info_handler
#   - trap_error_info::get_stack_trace
################################################################################
#
#_ source guard begin _#
[ -n "${__source_guard_84949D19_1C7A_40AF_BC28_BA5967A0B6CE:+has_value}" ] && return
__source_guard_84949D19_1C7A_40AF_BC28_BA5967A0B6CE=$(realpath -- "${BASH_SOURCE[0]}")
# the value of source guard is the canonical dir path of this script
readonly __source_guard_84949D19_1C7A_40AF_BC28_BA5967A0B6CE=${__source_guard_84949D19_1C7A_40AF_BC28_BA5967A0B6CE%/*}
#_ source guard end _#

set -eEu -o pipefail -o functrace

# show stack trace.
#
# usage:
#   trap_error_info::get_stack_trace <indentation> <hide level>
#
# - indentation default is empty("").
# - hide level default is 0.
#   level 0 means show from the caller level stack trace.
#
# the format of stack trace:
#   <func name>(<source file>:<line no>)
# example:
#   foo_function(bar.sh:42)
#
trap_error_info::get_stack_trace() {
  local indentation="${1:-}" hide_level="${2:-0}"
  local func_stack_size="${#FUNCNAME[@]}"

  TRAP_ERROR_INFO_STACK_TRACE=''

  local i stack_trace=
  for ((i = hide_level + 1; i < func_stack_size; i++)); do
    [ -n "${stack_trace:-}" ] && printf -v stack_trace '%s\n' "$stack_trace"
    printf -v stack_trace '%s%s%s(%s:%s)' "$stack_trace" "$indentation" "${FUNCNAME[i]}" "${BASH_SOURCE[i]}" "${BASH_LINENO[i - 1]}"
  done

  TRAP_ERROR_INFO_STACK_TRACE="$stack_trace"
}

# official document of `Bash Variables`, e.g.
#   BASH_SOURCE
#   BASH_LINENO
#   LINENO
#   BASH_COMMAND
# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
#
#
# related info:
#
# https://stackoverflow.com/questions/6928946/mysterious-lineno-in-bash-trap-err
# https://stackoverflow.com/questions/64786/error-handling-in-bash
# https://stackoverflow.com/questions/24398691/how-to-get-the-real-line-number-of-a-failing-bash-command
# https://unix.stackexchange.com/questions/39623/trap-err-and-echoing-the-error-line
# https://unix.stackexchange.com/questions/462156/how-do-i-find-the-line-number-in-bash-when-an-error-occured
# https://unix.stackexchange.com/questions/365113/how-to-avoid-error-message-during-the-execution-of-a-bash-script
# https://shapeshed.com/unix-exit-codes/#how-to-suppress-exit-statuses
# https://stackoverflow.com/questions/30078281/raise-error-in-a-bash-script/50265513#50265513
#
trap_error_info::_show_trapped_error_info() {
  local exit_code="$1" error_command_line="$2"

  {
    echo '================================================================================'
    echo "Trapped error!"
    echo
    echo "Exit status code: $exit_code"

    echo "Stack trace:"
    # set hide level 1, hide `trap_error_info::_show_trapped_error_info` self stack trace
    trap_error_info::get_stack_trace "  " 1
    echo "$TRAP_ERROR_INFO_STACK_TRACE"

    echo "Error code line:"
    echo "  $error_command_line"
    echo '================================================================================'
  } >&2
}

trap_error_info::register_show_error_info_handler() {
  trap 'trap_error_info::_show_trapped_error_info $? "$BASH_COMMAND"' ERR
}

################################################################################
# auto run logic when source
#
# auto call `trap_error_info::register_show_error_info_handler` when source this script;
# disable by define `TRAP_ERROR_NO_AUTO_REGISTER` var
################################################################################

if [ -z "${TRAP_ERROR_NO_AUTO_REGISTER+defined}" ]; then
  trap_error_info::register_show_error_info_handler
fi
