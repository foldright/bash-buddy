#!/bin/bash
set -eEuo pipefail
cd "$(dirname "$(readlink -f "$0")")"

source FIXME/lib/trap_error_info.sh
source FIXME/lib/common_utils.sh

################################################################################
# prepare
################################################################################

# shellcheck disable=SC2034
PREPARE_JDKS_INSTALL_BY_SDKMAN=(
  8.322.06.1-amzn
  11.0.14-ms
  17.0.2.8.1-amzn
)

source FIXME/lib/prepare_jdks.sh

source FIXME/lib/java_build_utils.sh

################################################################################
# ci build logic
################################################################################

FIXME PROJECT_ROOT_DIR=/path/to/project/root/dir
cd "$PROJECT_ROOT_DIR"

########################################
# default jdk 11, do build and test
########################################
default_build_jdk_version=11

prepare_jdks::switch_java_home_to_jdk "$default_build_jdk_version"

cu::head_line_echo "build and test with Java: $JAVA_HOME"
jvb::mvn_cmd clean install

########################################
# test multi-version java
########################################
for jhome_var_name in "${JDK_HOME_VAR_NAMES[@]}"; do
  # already tested by above `mvn install`
  [ "JDK${default_build_jdk_version}_HOME" = "$jhome_var_name" ] && continue

  prepare_jdks::switch_java_home_to_jdk "${!jhome_var_name}"

  cu::head_line_echo "test with Java: $JAVA_HOME"
  # just test without build
  jvb::mvn_cmd surefire:test
done
