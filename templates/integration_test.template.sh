#!/bin/bash
set -eEuo pipefail
# the canonical path of this script
SELF_PATH=$(realpath -- "$0")
readonly SELF_PATH SELF_DIR=${SELF_PATH%/*}
cd "$SELF_DIR"

FIXME BASH_BUDDY_ROOT=......
readonly BASH_BUDDY_ROOT
# shellcheck disable=SC1091
source "$BASH_BUDDY_ROOT/lib/trap_error_info.sh"
# shellcheck disable=SC1091
source "$BASH_BUDDY_ROOT/lib/common_utils.sh"
# shellcheck disable=SC1091
source "$BASH_BUDDY_ROOT/lib/java_utils.sh"
# shellcheck disable=SC1091
source "$BASH_BUDDY_ROOT/lib/maven_utils.sh"

################################################################################
# prepare
################################################################################

readonly default_build_jdk_version=17
readonly JDK_VERSIONS=(
  8
  11
  "$default_build_jdk_version"
  21
)

################################################################################
# ci build logic
################################################################################

FIXME PROJECT_ROOT=......
readonly PROJECT_ROOT
cd "$PROJECT_ROOT"

########################################
# do build and test by default version jdk
########################################

jvu::switch_to_jdk "$default_build_jdk_version"

cu::head_line_echo "build and test with Java: $JAVA_HOME"
mvu::mvn_cmd clean install

########################################
# test by multi-version jdk
########################################
for jdk_version in "${JDK_VERSIONS[@]}"; do
  # already tested above
  [ "$jdk_version" = "$default_build_jdk_version" ] && continue

  jvu::switch_to_jdk "$jdk_version"

  cu::head_line_echo "test with Java: $JAVA_HOME"
  # just test without build
  mvu::mvn_cmd surefire:test
done
