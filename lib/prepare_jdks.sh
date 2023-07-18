#!/bin/bash
#
# a lib to prepare jdks by sdkman https://sdkman.io/
#
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
#
#_ source guard begin _#
[ -z "${__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465:+has_value}" ] || return 0
__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly __source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465
#_ source guard end _#

set -eEuo pipefail

# shellcheck source=common_utils.sh
source "$__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465/common_utils.sh"
source "$__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465/java_utils.sh"

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
  jdk_home_path="$(prepare_jdks::_get_jdk_path_from_jdk_name_of_sdkman "$jdk_name_of_sdkman")"

  # install jdk by sdkman
  if [ ! -d "$jdk_home_path" ]; then
    cu::loose_run cu::log_then_run sdk install java "$jdk_name_of_sdkman" ||
      cu::die "fail to install jdk $jdk_name_of_sdkman by sdkman"
  fi
}

prepare_jdks::_get_latest_java_version() {
  (($# == 1)) || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local version_pattern="$1" input result
  # exclude
  #   - fx:       \.fx-
  #   - GraalVM:  -(grl|gln|nik)\>
  input=$(cat | grep -vE '\.fx-|-(grl|gln|nik|mandrel)\>')

  # 1. first find non-ea and non-fx versions
  result="$(echo "$input" | grep -vE '\.ea\.|\.fx-' | cu::get_latest_version_match "$version_pattern")"
  if [ -n "$result" ]; then
    echo "$result"
    return 0
  fi

  # 2. then find versions
  echo "$input" | cu::get_latest_version_match "$version_pattern"
}

# switch JAVA_HOME to target
#
# available switch target:
#   - version pattern, e.g.
#     - 11, 17
#     - 11.0, 11.0.14
#     - 11.0.14-ms
#       exact version of sdkman
#   - /path/to/java/home
#
# usage:
#   prepare_jdks::switch_to_jdk 17
#   prepare_jdks::switch_to_jdk 11.0.14-ms
#   prepare_jdks::switch_to_jdk /path/to/java/home
#
prepare_jdks::switch_to_jdk() {
  local verbose_mode=false prepare_mode=false
  while true; do
    case "$1" in
    -v)
      verbose_mode=true
      shift
      ;;
    -p)
      prepare_mode=true
      shift
      ;;
    *)
      break
      ;;
    esac
  done

  [ $# == 1 ] || cu::die "${FUNCNAME[0]} requires exact 1 argument! But provided $#: $*"

  local -r switch_target="$1"
  cu::is_blank_string "$switch_target" && cu::die "switch target($switch_target) is BLANK!"

  # 1. first check env var JDKx_HOME(e.g. JDK11_HOME)
  #
  # aka. set by java version, e.g.
  #   prepare_jdks::switch_to_jdk 11
  if cu::is_number_string "$switch_target"; then
    local jdk_home_var_name="JDK${switch_target}_HOME"

    # check env var JDKx_HOME is defined or not
    if [ -n "${!jdk_home_var_name+defined}" ]; then
      local jdk_home="${!jdk_home_var_name:-}"

      if jvu::_validate_java_home "$jdk_home"; then
        if ! $prepare_mode; then
          export JAVA_HOME="$jdk_home"
        fi
        if $verbose_mode; then
          cu::blue_echo "use \$$jdk_home_var_name($jdk_home) as switch target $switch_target" >&2
        fi
        return
      else
        cu::yellow_echo "found \$$jdk_home_var_name($jdk_home) for switch target $switch_target, but $_PREPARE_JDKS_VALIDATE_JAVA_HOME_ERR_MSG, ignored!" >&2
      fi
    fi
  fi

  # 2. then check switch is a directory or not
  #
  # aka. set by path of java installation, e.g.
  #   prepare_jdks::switch_to_jdk /path/to/java/home
  if [ -d "$switch_target" ]; then
    local jdk_home="$switch_target"

    if prepare_jdks::_validate_java_home "$jdk_home"; then
      if ! $prepare_mode; then
        export JAVA_HOME="$switch_target"
      fi
      if $verbose_mode; then
        cu::blue_echo "use $switch_target directory as switch target, since it is a existed directory" >&2
      fi
      return
    else
      cu::yellow_echo "found switch target $switch_target is a existed directory, but $_PREPARE_JDKS_VALIDATE_JAVA_HOME_ERR_MSG, ignored!" >&2
    fi
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
  if [ -z "$version" ]; then
    version=$(
      prepare_jdks::get_available_remote_java_versions_of_sdkman |
        prepare_jdks::_get_latest_java_version "$version_pattern"
    )
  fi

  [ -n "$version" ] || cu::die "fail to find available java version in sdkman for switch $switch_target!"

  prepare_jdks::install_jdk_by_sdkman "$version"

  local jdk_home
  jdk_home="$(prepare_jdks::_get_jdk_path_from_jdk_name_of_sdkman "$version")"

  if jvu::_validate_java_home "$jdk_home"; then
    if ! $prepare_mode; then
      export JAVA_HOME="$jdk_home"
    fi
    if $verbose_mode; then
      cu::blue_echo "use java version($version) in sdkman($jdk_home) as switch target $switch_target" >&2
    fi
  else
    cu::die "found available java version($version) in sdkman($jdk_home), but $_PREPARE_JDKS_VALIDATE_JAVA_HOME_ERR_MSG!"
  fi
}

# prepare jdks
#
# usage:
#   prepare_jdks::prepare_jdks <switch_target>...
#
# example:
#   prepare_jdks::prepare_jdks 8 11 17
#   prepare_jdks::prepare_jdks 11.0.14-ms 17.0.2-zulu
#   prepare_jdks::prepare_jdks 8 11.0.14-ms 18
#
# see: `prepare_jdks::switch_to_jdk`
#
prepare_jdks::prepare_jdks() {
  (($# > 0)) || cu::die "${FUNCNAME[0]} requires arguments! But no provided"

  cu::blue_echo "prepare jdks: ${*}"
  local switch_target
  for switch_target; do
    prepare_jdks::switch_to_jdk -p "$switch_target"
  done
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
