# <div align="center"><a href="#"><img src="docs/logo.png" alt="🚼 Bash Buddy"></a></div>

🚼 Bash Buddy(aka. BaBy) contains `bash` libs and tools that extracted from `CI` scripts of my projects.

-----------------------------------

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [⚒️ Tool](#-tool)
    - [`gen_source_guard`](#gen_source_guard)
- [🗂 Lib](#%F0%9F%97%82-lib)
    - [`trap_error_info.sh`](#trap_error_infosh)
    - [`common_utils.sh`](#common_utilssh)
    - [`java_build_utils.sh`](#java_build_utilssh)
    - [`prepare_jdks.sh`](#prepare_jdkssh)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

-----------------------------------

# ⚒️ Tool

## [`gen_source_guard`](bin/gen_source_guard)

Generate source guard to bash lib scripts.

Example:

```sh
$ gen_source_guard
#_ source guard begin _#
[ -z "${__source_guard_0EDD6400_96EC_43E4_871A_E65F6781B828:+has_value}" ] || return 0
__source_guard_0EDD6400_96EC_43E4_871A_E65F6781B828="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
readonly __source_guard_0EDD6400_96EC_43E4_871A_E65F6781B828
#_ source guard end _#
```

# 🗂 Lib

## [`trap_error_info.sh`](lib/trap_error_info.sh)

a common lib to show trapped error info including stack trace.

provide function `trap_error_info::register_show_error_info_handler`
to register the error-trap handler which show error info when trapped error.

by default, auto call `trap_error_info::register_show_error_info_handler` when source this script; disable by
define `TRAP_ERROR_NO_AUTO_REGISTER` var.

api functions:

- `trap_error_info::get_stack_trace`
- `trap_error_info::register_show_error_info_handler`

## [`common_utils.sh`](lib/common_utils.sh)

common util functions.

use short namespace `cu`, since these functions will be used frequently.

api functions:

- simple color print functions:
    - `cu::red_echo`
    - `cu::yellow_echo`
    - `cu::blue_echo`
    - `cu::head_line_echo`
- validation functions:
    - `cu::is_number_string`
    - `cu::is_blank_string`
- version related functions:
    - `cu::version_le`
    - `cu::version_lt`
    - `cu::version_ge`
    - `cu::version_gt`
    - `cu::is_version_match`
    - `cu::get_latest_version_match`
    - `cu::get_oldest_version_match`
- execution helper functions:
    - `cu::log_then_run`
    - `cu::loose_run`
    - `cu::die`

## [`java_build_utils.sh`](lib/java_build_utils.sh)

java and maven util functions for build.

api functions:

- java operation functions:
    - `jvb::get_java_version`
    - `jvb::java_cmd`
- maven operation functions:
    - `jvb::mvn_cmd`

## [`prepare_jdks.sh`](lib/prepare_jdks.sh)

a lib to prepare jdks by [sdkman](https://sdkman.io/).

api functions:

- `prepare_jdks::switch_to_jdk`
- `prepare_jdks::prepare_jdks`
- `prepare_jdks::install_jdk_by_sdkman`
- `prepare_jdks::load_sdkman`
- `prepare_jdks::install_sdkman`
