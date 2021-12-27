#!/bin/bash

[ -z "${__source_guard_E2EB46EC_DEB8_4818_8D4E_F425BDF4A275:+dummy}" ] || return 0
__source_guard_E2EB46EC_DEB8_4818_8D4E_F425BDF4A275="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly __source_guard_E2EB46EC_DEB8_4818_8D4E_F425BDF4A275

set -eEuo pipefail

# shellcheck source=common.sh
source "$__source_guard_E2EB46EC_DEB8_4818_8D4E_F425BDF4A275/common.sh"

#################################################################################
# root project common info
#################################################################################

# set project root dir to PROJECT_ROOT_DIR var
PROJECT_ROOT_DIR="$(readlink -f "$__source_guard_E2EB46EC_DEB8_4818_8D4E_F425BDF4A275/../../..")"
readonly PROJECT_ROOT_DIR

#################################################################################
# java operation functions
#################################################################################

__getJavaVersion() {
    "$JAVA_HOME/bin/java" -version 2>&1 | awk -F\" '/ version "/{print $2}'
}

# set env variable ENABLE_JAVA_RUN_DEBUG to enable java debug mode
JAVA_CMD() {
    logAndRun "$JAVA_HOME/bin/java" -Xmx128m -Xms128m -server -ea -Duser.language=en -Duser.country=US \
        ${ENABLE_JAVA_RUN_VERBOSE_CLASS+ -verbose:class} \
        ${ENABLE_JAVA_RUN_DEBUG+ -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=y,address=5005} \
        "$@"
}

#################################################################################
# maven operation functions
#################################################################################

MVN_CMD() {
    logAndRun "$PROJECT_ROOT_DIR/mvnw" -V --no-transfer-progress \
    ${DISABLE_GIT_DIRTY_CHECK+ -Dgit.dirty=false} \
    "$@"
}

mvnClean() {
    (
        cd "$PROJECT_ROOT_DIR"
        MVN_CMD clean || die "fail to mvn clean!"
    )
}

mvnBuildJar() {
    (
        cd "$PROJECT_ROOT_DIR"
        MVN_CMD install -DperformRelease -P '!gen-sign' || die "fail to build jar!"
    )
}

mvnCopyDependencies() {
    (
        cd "$PROJECT_ROOT_DIR"
        # https://maven.apache.org/plugins/maven-dependency-plugin/copy-dependencies-mojo.html
        MVN_CMD dependency:copy-dependencies -DincludeScope=test -DexcludeArtifactIds=jsr305,spotbugs-annotations || die "fail to mvn copy-dependencies!"
    )
}

extractFirstElementValueFromPom() {
    (($# == 2)) || die "${FUNCNAME[0]} need only 2 arguments, actual arguments: $*"

    local element=$1
    local pom_file=$2
    grep \<"$element"'>.*</'"$element"\> "$pom_file" | awk -F'</?'"$element"\> 'NR==1 {print $2}'
}
