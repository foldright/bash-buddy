#!/bin/bash
#
# a common lib to show trapped error info.
#
# provide function `trap_error_info::register_show_error_info_handler` to register
# the error-trap handler which show error info when trapped error.
#
# by default, auto register_show_error_info_handler when source this script;
# disable by define `TRAP_ERROR_NO_AUTO_REGISTER` var
#
#_ source guard start _#
[ -z "${__source_guard_84949D19_1C7A_40AF_BC28_BA5967A0B6CE:+dummy}" ] || return 0
__source_guard_84949D19_1C7A_40AF_BC28_BA5967A0B6CE="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly __source_guard_84949D19_1C7A_40AF_BC28_BA5967A0B6CE
#_ source guard end _#

set -eEu -o pipefail -o functrace

################################################################################
# api functions:
#   - trap_error_info::register_show_error_info_handler
#   - trap_error_info::show_stack_trace
################################################################################

# trap_error_info::_get_caller_line_no $level
# level = 0 means caller stack
#
# do NOT call this function in sub-shell!
# e.g. $(trap_error_info::_get_caller_line_no)
trap_error_info::_get_caller_line_no() {
    local level="$1"

    # level 0 of caller means self
    # level + 1, to skip `_get_caller_line_no` self
    caller $((level + 1)) | {
        local line_no _
        read -r line_no _
        printf "%s" "$line_no"
    }
}

# show stack trace with format: func name(source file: line no)
#
# usage:
#   trap_error_info::show_stack_trace <hide level> <indent>
#
# about hide level, default contains 2 extra level of implementation:
#   - trap_error_info::show_stack_trace
#   - trap_error_info::_get_caller_line_no
# set hide level to 2, hide this 2 xtra level of implementation.
#
# do NOT call this function in sub-shell!
trap_error_info::show_stack_trace() {
    local hide_level="${1:-0}" indent="${2:-}"
    local func_stack_size="${#FUNCNAME[@]}"

    local i
    for ((i = hide_level; i < func_stack_size; i++)); do
        printf "%s%s(%s:" "$indent" "${FUNCNAME[i]}" "${BASH_SOURCE[i]}"
        trap_error_info::_get_caller_line_no "$((i - 1))"
        printf ")\n"
    done
}

# official document of `Bash Variables`, e.g.
#   BASH_SOURCE
#   BASH_LINENO
#   LINENO
#   BASH_COMMAND
# https://www.gnu.org/software/bash/manual/html_node/Bash-Variables.html
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
trap_error_info::_show_trapped_error_info() {
    echo "$@"
    local exit_code="$1" error_code_line="$2"

    {
        echo '================================================================================'
        echo "Trapped error!"
        echo
        echo "Exit status code: $exit_code"
        echo "Stack trace:"
        trap_error_info::show_stack_trace 2 "  "
        echo "Error code line:"
        echo "  $error_code_line"
        echo '================================================================================'
    } >&2
}

trap_error_info::register_show_error_info_handler() {
    trap 'trap_error_info::_show_trapped_error_info $? "$BASH_COMMAND"' ERR
}

################################################################################
# auto run logic when source
#
# auto register_show_error_info_handler when source this script;
# disable by define `TRAP_ERROR_NO_AUTO_REGISTER` var
################################################################################

if [ -z "${TRAP_ERROR_NO_AUTO_REGISTER+defined}" ]; then
    trap_error_info::register_show_error_info_handler
fi
