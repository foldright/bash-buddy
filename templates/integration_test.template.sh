#!/bin/bash
set -eEuo pipefail
cd "$(dirname "$(readlink -f "$0")")"

FIXME BASH_BUDDY_ROOT="$(readlink -f path/to/bash-buddy/dir)"
readonly BASH_BUDDY_ROOT

source "$BASH_BUDDY_ROOT/lib/trap_error_info.sh"
source "$BASH_BUDDY_ROOT/lib/common_utils.sh"

################################################################################
# prepare
################################################################################

readonly default_build_jdk_version=11
# shellcheck disable=SC2034
readonly PREPARE_JDKS_INSTALL_BY_SDKMAN=(
  8
  "$default_build_jdk_version"
  17
)

source "$BASH_BUDDY_ROOT/lib/prepare_jdks.sh"

source "$BASH_BUDDY_ROOT/lib/maven_utils.sh"

################################################################################
# ci build logic
################################################################################

FIXME PROJECT_ROOT_DIR="$(readlink -f /path/to/project/root/dir)"
cd "$PROJECT_ROOT_DIR"

########################################
# do build and test by default version jdk
########################################

prepare_jdks::switch_to_jdk "$default_build_jdk_version"

cu::head_line_echo "build and test with JDK: $JAVA_HOME"
jvb::mvn_cmd clean install

########################################
# test by multi-version jdk
########################################
for jdk in "${PREPARE_JDKS_INSTALL_BY_SDKMAN[@]}"; do
  # already tested above
  [ "$jdk" = "$default_build_jdk_version" ] && continue

  prepare_jdks::switch_to_jdk "$jdk"

  cu::head_line_echo "test with JDK: $JAVA_HOME"
  # just test without build
  jvb::mvn_cmd surefire:test
done
