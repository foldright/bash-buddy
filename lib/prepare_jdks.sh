#!/bin/bash
#
# a lib to prepare jdks by sdkman https://sdkman.io/
#
#_ source guard start _#
[ -z "${__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465:+has_value}" ] || return 0
__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly __source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465
#_ source guard end _#

set -eEuo pipefail

# shellcheck source=common_utils.sh
source "$__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465/common_utils.sh"

################################################################################
# api functions:
#
#   - prepare_jdks::switch_to_jdk
#
#   - prepare_jdks::prepare_jdks
#
#   - prepare_jdks::install_jdk_by_sdkman
#   - prepare_jdks::load_sdkman
#   - prepare_jdks::install_sdkman
################################################################################

# install sdkman.
#
# shellcheck disable=SC2120
prepare_jdks::install_sdkman() {
  (($# == 0)) || cu::die "${FUNCNAME[0]} requires no arguments! But provided $#: $*"

  PREPARE_JDKS_IS_THIS_TIME_INSTALLED_SDKMAN="${PREPARE_JDKS_IS_THIS_TIME_INSTALLED_SDKMAN:-false}"

  # install sdkman if not installed yet
  if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
    [ -d "$HOME/.sdkman" ] && rm -rf "$HOME/.sdkman"

    curl -s get.sdkman.io | bash || cu::die "fail to install sdkman"
    PREPARE_JDKS_IS_THIS_TIME_INSTALLED_SDKMAN=true

    # FIXME: hard-coded config logic
    {
      echo sdkman_auto_answer=true
      echo sdkman_auto_selfupdate=false
      echo sdkman_disable_auto_upgrade_check=true
    } >>"$HOME/.sdkman/etc/config"
  fi
}

# load sdkman.
#
# install sdkman if not installed yet.
#
# shellcheck disable=SC2120
prepare_jdks::load_sdkman() {
  (($# == 0)) || cu::die "${FUNCNAME[0]} requires no arguments! But provided $#: $*"

  prepare_jdks::install_sdkman

  # load sdkman if not loaded yet
  if ! command -v sdk &>/dev/null; then
    # shellcheck disable=SC1090
    cu::loose_run source "$HOME/.sdkman/bin/sdkman-init.sh"
  fi
}

prepare_jdks::_get_sdkman_ls_java_content() {
  [ -n "${_PREPARE_JDKS_SDKMAN_LS_JAVA_CONTENT:-}" ] && {
    echo "$_PREPARE_JDKS_SDKMAN_LS_JAVA_CONTENT"
    return
  }

  _PREPARE_JDKS_SDKMAN_LS_JAVA_CONTENT="$(cu::loose_run sdk ls java | sed -n '/^ Vendor/,/^===========/p')"
  echo "$_PREPARE_JDKS_SDKMAN_LS_JAVA_CONTENT"
}

# shellcheck disable=SC2120
prepare_jdks::ls_java() {
  (($# == 0)) || cu::die "${FUNCNAME[0]} requires no arguments! But provided $#: $*"

  prepare_jdks::load_sdkman

  cu::blue_echo "sdk ls java:"
  prepare_jdks::_get_sdkman_ls_java_content
}

# shellcheck disable=SC2120
prepare_jdks::get_available_java_versions_of_sdkman() {
  (($# == 0)) || cu::die "${FUNCNAME[0]} requires no arguments! But provided $#: $*"

  [ -n "${_PREPARE_JDKS_AVAILABLE_JAVA_VERSIONS_OF_SDKMAN:-}" ] && {
    echo "$_PREPARE_JDKS_AVAILABLE_JAVA_VERSIONS_OF_SDKMAN"
    return
  }

  prepare_jdks::load_sdkman >&2

  _PREPARE_JDKS_AVAILABLE_JAVA_VERSIONS_OF_SDKMAN="$(
    prepare_jdks::_get_sdkman_ls_java_content |
      awk -F'[ \\t]*\\|[ \\t]*' 'NR > 2 && /\|/ {print $NF}' |
      sort -Vr
  )"

  echo "$_PREPARE_JDKS_AVAILABLE_JAVA_VERSIONS_OF_SDKMAN"
}

# shellcheck disable=SC2120
prepare_jdks::get_available_local_java_versions_of_sdkman() {
  (($# == 0)) || cu::die "${FUNCNAME[0]} requires no arguments! But provided $#: $*"

  [ -n "${_PREPARE_JDKS_AVAILABLE_LOCAL_JAVA_VERSIONS_OF_SDKMAN:-}" ] && {
    echo "$_PREPARE_JDKS_AVAILABLE_LOCAL_JAVA_VERSIONS_OF_SDKMAN"
    return
  }

  prepare_jdks::load_sdkman >&2

  _PREPARE_JDKS_AVAILABLE_LOCAL_JAVA_VERSIONS_OF_SDKMAN="$(
    printf '%s\n' "$SDKMAN_CANDIDATES_DIR/java"/*/ |
      awk -F/ '$(NF-1) !~ /^current$/ {print $(NF-1)}' |
      sort -Vr
  )"

  echo "$_PREPARE_JDKS_AVAILABLE_LOCAL_JAVA_VERSIONS_OF_SDKMAN"
}

# shellcheck disable=SC2120
prepare_jdks::get_available_remote_java_versions_of_sdkman() {
  (($# == 0)) || cu::die "${FUNCNAME[0]} requires no arguments! But provided $#: $*"

  [ -n "${_PREPARE_JDKS_AVAILABLE_REMOTE_JAVA_VERSIONS_OF_SDKMAN:-}" ] && {
    echo "$_PREPARE_JDKS_AVAILABLE_REMOTE_JAVA_VERSIONS_OF_SDKMAN"
    return
  }

  prepare_jdks::load_sdkman >&2

  _PREPARE_JDKS_AVAILABLE_REMOTE_JAVA_VERSIONS_OF_SDKMAN="$(
    prepare_jdks::_get_sdkman_ls_java_content |
      awk -F'[ \\t]*\\|[ \\t]*' 'NR > 2 && /\|/ && $5 !~ /^local / {print $NF}' |
      sort -Vr
  )"

  echo "$_PREPARE_JDKS_AVAILABLE_REMOTE_JAVA_VERSIONS_OF_SDKMAN"
}

prepare_jdks::_get_jdk_path_from_jdk_name_of_sdkman() {
  local jdk_name_of_sdkman="$1"
  local jdk_home_path="$SDKMAN_CANDIDATES_DIR/java/$jdk_name_of_sdkman"
  echo "$jdk_home_path"
}

# install the jdk by sdkman.
prepare_jdks::install_jdk_by_sdkman() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  prepare_jdks::load_sdkman

  local jdk_name_of_sdkman="$1" jdk_home_path
  jdk_home_path="$(
    prepare_jdks::_get_jdk_path_from_jdk_name_of_sdkman "$jdk_name_of_sdkman"
  )"

  # install jdk by sdkman
  if [ ! -d "$jdk_home_path" ]; then
    cu::loose_run cu::log_then_run sdk install java "$jdk_name_of_sdkman" ||
      cu::die "fail to install jdk $jdk_name_of_sdkman by sdkman"
  fi
}

# shellcheck disable=SC2120
prepare_jdks::_get_latest_java_version() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local version_pattern="$1" input result
  input=$(cat)

  # 1. first find non-ea and non-fx versions
  result="$(echo "$input" | grep -vE '\.ea\.|\.fx-' | cu::get_latest_version "$version_pattern")"
  if [ -n "$result" ]; then
    echo "$result"
    return 0
  fi

  # 2. then find versions
  echo "$input" | cu::get_latest_version "$version_pattern"
}

prepare_jdks::_validate_java_home() {
  local -r switch_target="$1"

  [ -e "$JAVA_HOME" ] || cu::die "jdk $switch_target NOT existed: $JAVA_HOME"
  [ -d "$JAVA_HOME" ] || cu::die "jdk $switch_target is NOT directory: $JAVA_HOME"

  local java_cmd="$JAVA_HOME/bin/java"
  [ -f "$java_cmd" ] || cu::die "\$JAVA_HOME/bin/java ($java_cmd) of $switch_target is NOT found!"
  [ -x "$java_cmd" ] || cu::die "\$JAVA_HOME/bin/java ($java_cmd) of $switch_target is NOT executable!"
}

# usage:
#   prepare_jdks::switch_to_jdk 11
#   prepare_jdks::switch_to_jdk /path/to/java_home
prepare_jdks::switch_to_jdk() {
  [ $# == 1 ] || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local -r switch_target="$1"
  [ -n "$switch_target" ] || cu::die "jdk $switch_target is blank"

  # 1. first check env var JDK11_HOME
  #
  # set by java version, e.g.
  #   prepare_jdks::switch_to_jdk 11
  if cu::is_number_string "$switch_target"; then
    local java_home_var_name="JDK${switch_target}_HOME"
    if [ -d "${!java_home_var_name:-}" ]; then
      export JAVA_HOME="${!java_home_var_name:-}"
      cu::yellow_echo "${FUNCNAME[0]} $*: use \$$java_home_var_name($JAVA_HOME)"

      prepare_jdks::_validate_java_home "$switch_target"
      return
    fi
  fi

  # 2. set by path of java installation
  if [ -d "$switch_target" ]; then
    # set by java home path
    export JAVA_HOME="$switch_target"
    cu::yellow_echo "${FUNCNAME[0]} $*: use switch target $JAVA_HOME as java home directory"

    prepare_jdks::_validate_java_home "$switch_target"
    return
  fi

  # 3. set by java version pattern of sdkman
  local -r version_pattern="$switch_target"
  local version
  # 3.1 check *local* java versions of sdkman
  version=$(
    prepare_jdks::get_available_local_java_versions_of_sdkman |
      prepare_jdks::_get_latest_java_version "$version_pattern"
  )
  # 3.2 check *remote* java versions of sdkman
  if [ -z "${version}" ]; then
    version=$(
      prepare_jdks::get_available_remote_java_versions_of_sdkman |
        prepare_jdks::_get_latest_java_version "$version_pattern"
    )
  fi

  [ -n "$version" ] || cu::die "fail to switch $switch_target"

  prepare_jdks::install_jdk_by_sdkman "$version"
  JAVA_HOME="$(prepare_jdks::_get_jdk_path_from_jdk_name_of_sdkman "$version")"
  export JAVA_HOME
  prepare_jdks::_validate_java_home "$switch_target"
}

# prepare jdks:
#
# usage:
#   prepare_jdks::prepare_jdks <switch_target>...
#
# example:
#   prepare_jdks::prepare_jdks 8 11 17
#   prepare_jdks::prepare_jdks 11.0.14-ms 17.0.2-zulu
prepare_jdks::prepare_jdks() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  cu::blue_echo "prepare jdks(${*}) by switch_to_jdk"
  local switch_target
  for switch_target; do
    prepare_jdks::switch_to_jdk "$switch_target"
  done
  echo
}

################################################################################
# auto run logic when source
#
# auto load sdkman.
#   disable by define `PREPARE_JDKS_NO_AUTO_LOAD_SDKMAN` var
#
# auto prepare jdks,
#   if `PREPARE_JDKS_INSTALL_BY_SDKMAN` is has values
################################################################################

prepare_jdks::__auto_run_when_source() {
  [ -n "${PREPARE_JDKS_NO_AUTO_LOAD_SDKMAN+defined}" ] && return 0

  prepare_jdks::load_sdkman

  case "${PREPARE_JDKS_AUTO_SHOW_LS_JAVA:-}" in
  never) ;;
  always)
    prepare_jdks::ls_java
    ;;
  when_sdkman_install | '')
    if "$PREPARE_JDKS_IS_THIS_TIME_INSTALLED_SDKMAN"; then
      prepare_jdks::ls_java
    fi
    ;;
  esac

  if [[ -z "${PREPARE_JDKS_NO_AUTO_INSTALL_BY_SDKMAN+defined}" && -n "${PREPARE_JDKS_INSTALL_BY_SDKMAN:+has_values}" ]]; then
    prepare_jdks::prepare_jdks "${PREPARE_JDKS_INSTALL_BY_SDKMAN[@]}"
  fi
}

prepare_jdks::__auto_run_when_source
