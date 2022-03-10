#!/bin/bash
set -eEuo pipefail
cd "$(dirname "$(readlink -f "$0")")"

FIXME BASH_BUDDY_ROOT=/path/to/bash_buddy/dir

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

source "$BASH_BUDDY_ROOT/lib/java_build_utils.sh"

################################################################################
# ci build logic
################################################################################

FIXME PROJECT_ROOT_DIR=/path/to/project/root/dir
cd "$PROJECT_ROOT_DIR"

########################################
# default jdk 11, do build and test
########################################

prepare_jdks::switch_to_jdk "$default_build_jdk_version"

cu::head_line_echo "build and test with Java: $JAVA_HOME"
jvb::mvn_cmd clean install

########################################
# test multi-version java
########################################
for jdk in "${PREPARE_JDKS_INSTALL_BY_SDKMAN[@]}"; do
  # already tested by above `mvn install`
  [ "$jdk" = "$default_build_jdk_version" ] && continue

  prepare_jdks::switch_to_jdk "$jdk"

  cu::head_line_echo "test with Java: $JAVA_HOME"
  # just test without build
  jvb::mvn_cmd surefire:test
done
