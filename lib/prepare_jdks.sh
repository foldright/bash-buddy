#!/bin/bash
#
# a lib to prepare jdks by sdkman https://sdkman.io/
#
#_ source guard start _#
[ -z "${__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465:+dummy}" ] || return 0
__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly __source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465
#_ source guard end _#

set -eEuo pipefail

# shellcheck source=common_utils.sh
source "$__source_guard_E2AA8C4F_215B_4CDA_9816_429C7A2CD465/common_utils.sh"

################################################################################
# api functions:
#
#   - prepare_jdks::prepare_jdks
#   - prepare_jdks::switch_java_home_to_jdk
#
#   - prepare_jdks::install_jdk_by_sdkman
#   - prepare_jdks::load_sdkman
#   - prepare_jdks::install_sdkman
################################################################################

prepare_jdks::install_sdkman() {
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
# install sdkman if not installed yet.
prepare_jdks::load_sdkman() {
    prepare_jdks::install_sdkman

    # load sdkman if not loaded yet
    if ! command -v sdk &>/dev/null; then
        # shellcheck disable=SC1090
        cu::loose_run source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi
}

prepare_jdks::ls_java() {
    prepare_jdks::load_sdkman

    cu::loose_run cu::log_then_run sdk ls java | sed -n '/^ Vendor/,/^===========/p'
}

prepare_jdks::_get_jdk_path_from_jdk_name_of_sdkman() {
    local jdk_name_of_sdkman="$1"
    echo "$SDKMAN_CANDIDATES_DIR/java/$jdk_name_of_sdkman"
}

# install the jdk by sdkman if not installed yet.
prepare_jdks::install_jdk_by_sdkman() {
    prepare_jdks::load_sdkman

    local jdk_name_of_sdkman="$1"
    local jdk_home_path
    jdk_home_path="$(
        prepare_jdks::_get_jdk_path_from_jdk_name_of_sdkman "$jdk_name_of_sdkman"
    )"

    # install jdk by sdkman
    if [ ! -d "$jdk_home_path" ]; then
        cu::loose_run cu::log_then_run sdk install java "$jdk_name_of_sdkman" ||
            cu::die "fail to install jdk $jdk_name_of_sdkman by sdkman"
    fi
}

prepare_jdks::_prepare_one_jdk() {
    local jdk_name_of_sdkman="$1"
    local jdk_major_version="${jdk_name_of_sdkman//.*/}"

    # java_home_var_name like JDK7_HOME, JDK11_HOME
    local java_home_var_name="JDK${jdk_major_version}_HOME"

    if [ -z "${!java_home_var_name:-}" ]; then
        # 1. prepare jdk home global var
        #
        # Dynamic variable names in Bash
        # https://stackoverflow.com/a/55331060/922688
        #
        # read value of dynamic variable by:
        #   "${!var_which_value_is_var_name}"
        # assign value to of dynamic variable by:
        #   printf -v "$var_which_value_is_var_name" %s value
        local jdk_home_path
        jdk_home_path="$(prepare_jdks::_get_jdk_path_from_jdk_name_of_sdkman "$jdk_name_of_sdkman")"

        printf -v "$java_home_var_name" %s "${jdk_home_path}"

        JDK_HOME_VAR_NAMES=(
            ${JDK_HOME_VAR_NAMES[@]:+"${JDK_HOME_VAR_NAMES[@]}"}
            "$java_home_var_name"
        )

        # 2. install jdk by sdkman
        prepare_jdks::install_jdk_by_sdkman "$jdk_name_of_sdkman"
    else
        cu::yellow_echo "$java_home_var_name is already prepared: ${!java_home_var_name}"
        cu::yellow_echo "  so skip install $jdk_name_of_sdkman by sdkman"
    fi
}

# prepare jdks:
#
# usage:
#   prepare_jdks::prepare_jdks <jdk_name_of_sdkman>...
#
# example:
#   prepare_jdks::prepare_jdks 11.0.14-ms
#   prepare_jdks::prepare_jdks 11.0.14-ms 17.0.2-zulu
#
# do the below works:
#   1. prepare jdk home global var, like
#       JDK7_HOME=/path/to/jdk7/home
#       JDK11_HOME=/path/to/jdk11/home
#   2. prepare jdk home global array var `JDK_HOME_VAR_NAMES`, like
#      JDK_HOME_VAR_NAMES=($JDK7_HOME $JDK11_HOME)
#   3. install jdk by sdkman
prepare_jdks::prepare_jdks() {
    JDK_HOME_VAR_NAMES=()

    local jdk_name_of_sdkman
    for jdk_name_of_sdkman in "$@"; do
        prepare_jdks::_prepare_one_jdk "$jdk_name_of_sdkman"
    done

    cu::blue_echo "prepared jdks:"
    local java_home_var_name
    for java_home_var_name in "${JDK_HOME_VAR_NAMES[@]}"; do
        cu::blue_echo "$java_home_var_name: ${!java_home_var_name}"
    done
}

# usage:
#   prepare_jdks::switch_java_home_to_jdk 11
#   prepare_jdks::switch_java_home_to_jdk /path/to/java_home
prepare_jdks::switch_java_home_to_jdk() {
    [ $# == 1 ] || cu::die "${FUNCNAME[0]} need 1 argument! But provided: $*"

    local -r switch_target="$1"
    [ -n "$switch_target" ] || cu::die "jdk $switch_target is blank"

    if cu::is_number_string "$switch_target"; then
        # set by java version, e.g.
        #   prepare_jdks::switch_java_home_to_jdk 11
        local java_home_var_name="JDK${switch_target}_HOME"
        export JAVA_HOME="${!java_home_var_name:-}"

        [ -n "$JAVA_HOME" ] || cu::die "JAVA_HOME of java version $switch_target($java_home_var_name) is unset or blank: $JAVA_HOME"
    else
        # set by java home path
        export JAVA_HOME="$switch_target"
    fi

    [ -e "$JAVA_HOME" ] || cu::die "jdk $switch_target NOT existed: $JAVA_HOME"
    [ -d "$JAVA_HOME" ] || cu::die "jdk $switch_target is NOT directory: $JAVA_HOME"

    local java_cmd="$JAVA_HOME/bin/java"
    [ -f "$java_cmd" ] || cu::die "\$JAVA_HOME/bin/java ($java_cmd) is NOT found!"
    [ -x "$java_cmd" ] || cu::die "\$JAVA_HOME/bin/java ($java_cmd) is NOT executable!"
}

################################################################################
# auto load sdkman.
#   disable by define `PREPARE_JDKS_NO_AUTO_LOAD_SDKMAN` var
#
# auto prepare jdks,
#   if `PREPARE_JDKS_INSTALL_BY_SDKMAN` is has values
################################################################################

if [ -z "${PREPARE_JDKS_NO_AUTO_LOAD_SDKMAN+defined}" ]; then
    prepare_jdks::load_sdkman
fi

if "$PREPARE_JDKS_IS_THIS_TIME_INSTALLED_SDKMAN"; then
    prepare_jdks::ls_java
fi

if [ -n "${PREPARE_JDKS_INSTALL_BY_SDKMAN:+has_values}" ]; then
    prepare_jdks::prepare_jdks "${PREPARE_JDKS_INSTALL_BY_SDKMAN[@]}"
fi
