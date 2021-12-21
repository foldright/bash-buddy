#!/bin/bash
set -eEuo pipefail
cd "$(dirname "$(readlink -f "$0")")"

source ../lib/common_build.sh
source ../lib/prepare_jdk.sh

showInfoOfSdkman

################################################################################
# check integration_test_pre script
# source if existed
################################################################################

readonly integration_test_pre='../../integration_test_pre.sh'
# shellcheck disable=SC1090
[ -f "$integration_test_pre" ] && source "$integration_test_pre"

################################################################################
# check integration_test_ops script, must existed
#
# prepare function runIntegrationTestOps
################################################################################

integration_test_ops='../../integration_test_ops.sh'
[ -f "$integration_test_ops" ] || die "Not found $integration_test_ops script!"

integration_test_ops="$(readlink -f "$integration_test_ops")"
readonly integration_test_ops

runIntegrationTestOps() {
    headInfo "test with Java: $JAVA_HOME"
    # shellcheck disable=SC1090
    source "$integration_test_ops"
}

################################################################################
# integration test flow
################################################################################

cd "$PROJECT_ROOT_DIR"

# test multi-version java home env
# shellcheck disable=SC2154
for jhome_var_name in "${java_home_var_names[@]}"; do
    export JAVA_HOME=${!jhome_var_name}
    runIntegrationTestOps
done
