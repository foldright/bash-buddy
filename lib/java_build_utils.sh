#!/bin/bash
#
# java and maven util functions for build.
#
################################################################################
# api functions:
#
#  - java operation functions:
#   - jvb::get_java_version
#   - jvb::java_cmd
#  - maven operation functions:
#   - jvb::mvn_cmd
################################################################################
#
#_ source guard start _#
[ -z "${__source_guard_364DF1B5_9CA2_44D3_9C62_CDF6C2ECB24F:+has_value}" ] || return 0
__source_guard_364DF1B5_9CA2_44D3_9C62_CDF6C2ECB24F="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly __source_guard_364DF1B5_9CA2_44D3_9C62_CDF6C2ECB24F
#_ source guard end _#

set -eEuo pipefail

# shellcheck source=common_utils.sh
source "$__source_guard_364DF1B5_9CA2_44D3_9C62_CDF6C2ECB24F/common_utils.sh"

#################################################################################
# java operation functions
#################################################################################

# output the java version extracted from `java -version`
jvb::get_java_version() {
  (($# <= 1)) || cu::die "${FUNCNAME[0]} requires at most 1 argument! But provided $#: $*"

  local java_home_path="${1:-$JAVA_HOME}"
  "$java_home_path/bin/java" -version 2>&1 | awk -F\" '/ version "/{print $2}'
}

# FIXME hard code memery settings
# shellcheck disable=SC2034
readonly JVB_DEFAULT_JAVA_OPTS=(
  -Xmx256m -Xms256m
  -server -ea
  -Duser.language=en -Duser.country=US
)

readonly JVB_JAVA_OPT_DEFAULT_DEBUG_PORT=5050

# set env variable ENABLE_JAVA_RUN_DEBUG to enable java debug mode
jvb::java_cmd() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  local debug_opts="-Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=${JVB_JAVA_OPT_DEBUG_PORT}"

  cu::log_then_run "$JAVA_HOME/bin/java" \
    "${JVB_JAVA_OPTS[@]}" \
    ${JVB_ENABLE_JAVA_RUN_VERBOSE_CLASS+-verbose:class} \
    ${JVB_ENABLE_JAVA_RUN_DEBUG+$debug_opts} \
    "$@"
}

#################################################################################
# maven operation functions
#################################################################################

readonly JVB_DEFAULT_MVN_OPTS=(
  -V --no-transfer-progress
)

jvb::_find_mvn_cmd_path() {
  if [ -n "${_JVB_MVN_PATH:-}" ]; then
    echo "$_JVB_MVN_PATH"
    return
  fi

  local -r maven_wrapper_name="mvnw"

  # 1. find the mvnw from project root dir
  if [ -n "${PROJECT_ROOT_DIR:-}" ] && [ -e "$PROJECT_ROOT_DIR/$maven_wrapper_name" ]; then
    _JVB_MVN_PATH="$PROJECT_ROOT_DIR/$maven_wrapper_name"
    echo "$_JVB_MVN_PATH"
    return
  fi

  # 2. find mvnw from parent dirs
  local d="$PWD"
  while true; do
    local mvnw_path="$d/$maven_wrapper_name"
    [ -x "$mvnw_path" ] && {
      _JVB_MVN_PATH="$mvnw_path"
      echo "$_JVB_MVN_PATH"
      return
    }

    [ "/" = "$d" ] && break
    d=$(dirname "$d")
  done

  # 3. find mvn from $PATH
  if command -v mvn &>/dev/null; then
    _JVB_MVN_PATH=mvn
    echo "$_JVB_MVN_PATH"
    return
  fi

  cu::die "$(
    echo "fail to find mvn cmd!"
    echo "found locations:"
    echo "  - \$PROJECT_ROOT_DIR/mvnw($PROJECT_ROOT_DIR/mvnw)"
    echo "  - \$PWD/mvnw($PWD/mvnw) and its parent dirs"
    echo "  - mvn on \$PATH"
  )"
}

jvb::mvn_cmd() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  # FIXME hard code logic for `DISABLE_GIT_DIRTY_CHECK`
  cu::log_then_run "$(jvb::_find_mvn_cmd_path)" \
    "${JVB_MVN_OPTS[@]}" \
    ${DISABLE_GIT_DIRTY_CHECK+-Dgit.dirty=false} \
    "$@"
}

jvb::get_mvn_local_repository_dir() {
  (($# == 0)) || cu::die "${FUNCNAME[0]} requires no arguments! But provided $#: $*"

  if [ -z "${_JVB_MVN_LOCAL_REPOSITORY_DIR:-}" ]; then
    echo "$_JVB_MVN_LOCAL_REPOSITORY_DIR"
  fi

  _JVB_MVN_LOCAL_REPOSITORY_DIR="$(
    jvb::mvn_cmd --no-transfer-progress help:evaluate -Dexpression=settings.localRepository |
      grep '^/'
  )"

  [ -n "${_JVB_MVN_LOCAL_REPOSITORY_DIR:-}" ] || cu::die "Fail to find maven local repository directory"
}

################################################################################
# auto run logic when source
################################################################################

jvb::__auto_run_when_source() {
  # set VAR if absent

  if [ -z "${JVB_JAVA_OPT_DEBUG_PORT:-}" ]; then
    JVB_JAVA_OPT_DEBUG_PORT="$JVB_JAVA_OPT_DEFAULT_DEBUG_PORT"
  fi

  if [ -z "${JVB_JAVA_OPTS[*]:-}" ]; then
    JVB_JAVA_OPTS=("${JVB_DEFAULT_JAVA_OPTS[@]}")
  fi

  if [ -z "${JVB_MVN_OPTS[*]:-}" ]; then
    JVB_MVN_OPTS=("${JVB_DEFAULT_MVN_OPTS[@]}")
  fi
}

jvb::__auto_run_when_source
