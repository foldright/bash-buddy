#!/bin/bash
#
# java util functions.
#
################################################################################
# api functions:
#
#  - java operation functions:
#   - jvu::get_java_version
#   - jvu::java_cmd
################################################################################
#
#_ source guard begin _#
[ -n "${source_guard_ED79675F_4289_4394_A843_03D06DB48AFA:+has_value}" ] && return
source_guard_ED79675F_4289_4394_A843_03D06DB48AFA=$(realpath -- "${BASH_SOURCE[0]}")
# the value of source guard is the canonical dir path of this script
readonly source_guard_ED79675F_4289_4394_A843_03D06DB48AFA=${source_guard_ED79675F_4289_4394_A843_03D06DB48AFA%/*}
#_ source guard end _#

set -eEuo pipefail

# shellcheck source=common_utils.sh
source "$source_guard_ED79675F_4289_4394_A843_03D06DB48AFA/common_utils.sh"

#################################################################################
# java info functions
#################################################################################

# output the java version extracted from `java -version`
jvu::get_java_version() {
  (($# <= 1)) || cu::die "${FUNCNAME[0]} requires at most 1 argument! But provided $#: $*"

  local java_home_path="${1:-$JAVA_HOME}"
  "$java_home_path/bin/java" -version 2>&1 | awk -F\" '/ version "/{print $2}'
}

#################################################################################
# java operation functions
#################################################################################

jvu::_validate_java_home() {
  _JVU_VALIDATE_JAVA_HOME_ERR_MSG=

  local -r java_home="$1"
  if cu::is_blank_string "$java_home"; then
    _JVU_VALIDATE_JAVA_HOME_ERR_MSG="java home value($java_home) is BLANK"
    return 1
  fi

  if [ ! -e "$java_home" ]; then
    _JVU_VALIDATE_JAVA_HOME_ERR_MSG="java home value($java_home) is NOT a existed file"
    return 1
  fi
  if [ ! -d "$java_home" ]; then
    _JVU_VALIDATE_JAVA_HOME_ERR_MSG="java home value($java_home) is NOT a directory"
    return 1
  fi

  local java_path="$java_home/bin/java"
  if [ ! -f "$java_path" ]; then
    _JVU_VALIDATE_JAVA_HOME_ERR_MSG="java_home/bin/java($java_path) is NOT existed"
    return 1
  fi
  if [ ! -x "$java_path" ]; then
    _JVU_VALIDATE_JAVA_HOME_ERR_MSG="java_home/bin/java($java_path) is NOT executable"
    return 1
  fi
}

# switch JAVA_HOME to target
#
# available switch target:
#   - version pattern, e.g. 11, 17
#     determinate JAVA_HOME by env var JAVAx_HOME
#   - /path/to/java/home
#
# usage:
#   jvu::switch_to_jdk 17
#   jvu::switch_to_jdk /path/to/java/home
#
jvu::switch_to_jdk() {
  [ $# == 1 ] || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local -r switch_target="$1"
  cu::is_blank_string "$switch_target" && cu::die "switch target($switch_target) is BLANK!"

  # 1. first check env var JAVAx_HOME(e.g. JAVA11_HOME)
  #
  # aka. set by java version, e.g.
  #   jvu::switch_to_jdk 11
  if cu::is_number_string "$switch_target"; then
    local jdk_home_var_name="JAVA${switch_target}_HOME"
    # check env var JAVAx_HOME is defined or not
    if [ -z "${!jdk_home_var_name+defined}" ]; then
      cu::die "use \$$jdk_home_var_name as java home for switch target($switch_target), but \$$jdk_home_var_name is NOT defined!"
    fi
    local jdk_home="${!jdk_home_var_name:-}"
    if ! jvu::_validate_java_home "$jdk_home"; then
      cu::die "use \$$jdk_home_var_name($jdk_home) as java home for switch target($switch_target), but $_JVU_VALIDATE_JAVA_HOME_ERR_MSG!"
    fi

    export JAVA_HOME="$jdk_home"
    return
  fi

  # 2. then switch as a directory
  #
  # aka. set by path of java installation, e.g.
  #   jvu::switch_to_jdk /path/to/java/home
  local jdk_home="$switch_target"
  if ! jvu::_validate_java_home "$jdk_home"; then
    cu::die "use switch target($switch_target) as java home, but $_JVU_VALIDATE_JAVA_HOME_ERR_MSG!" >&2
  fi
  export JAVA_HOME="$jdk_home"
}

readonly JVU_DEFAULT_JAVA_OPTS=(
  -ea
  -Duser.language=en -Duser.country=US
  -Dfile.encoding=UTF-8
)

readonly JVU_JAVA_OPT_DEFAULT_DEBUG_PORT=5050

# set env variable ENABLE_JAVA_RUN_DEBUG to enable java debug mode
jvu::java_cmd() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  local debug_opts="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=${JVU_JAVA_OPT_DEBUG_PORT}"

  cu::log_then_run "$JAVA_HOME/bin/java" \
    "${JVU_JAVA_OPTS[@]}" \
    ${JVU_ENABLE_JAVA_RUN_VERBOSE_CLASS+-verbose:class} \
    ${JVU_ENABLE_JAVA_RUN_DEBUG+$debug_opts} \
    "$@"
}

################################################################################
# auto run logic when source
################################################################################

jvu::__detect_java_home_when_github_actions() {
  [[ "${GITHUB_ACTIONS:-}" = true ]] || return 0

  local jh_name matched_version jh assignment
  local -a detected=()
  for jh_name in "${!JAVA_HOME_@}"; do
    [[ "$jh_name" =~ ^JAVA_HOME_([0-9]+)_ ]] || continue
    matched_version="${BASH_REMATCH[1]}"

    jh="${!jh_name:-}"
    [ -d "$jh" ] || continue

    printf -v assignment 'JAVA%q_HOME=%q' "$matched_version" "$jh"
    detected=(${detected[@]:+"${detected[@]}"} "$assignment")
  done

  (("${#detected[@]}" > 0)) || return 0
  cu::yellow_echo "Detected JAVA_HOME when running in GitHub Actions:"
  for assignment in "${detected[@]}"; do
    # shellcheck disable=SC2163
    export "$assignment"
    echo "  export $assignment"
  done
}

jvu::__auto_run_when_source() {
  # set VAR if absent

  if [ -z "${JVU_JAVA_OPT_DEBUG_PORT:-}" ]; then
    JVU_JAVA_OPT_DEBUG_PORT="$JVU_JAVA_OPT_DEFAULT_DEBUG_PORT"
  fi

  if [ -z "${JVU_JAVA_OPTS[*]:-}" ]; then
    JVU_JAVA_OPTS=("${JVU_DEFAULT_JAVA_OPTS[@]}")
  fi

  jvu::__detect_java_home_when_github_actions
}

jvu::__auto_run_when_source
