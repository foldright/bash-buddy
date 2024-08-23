# <div align="center"><a href="#"><img src="https://github.com/foldright/bash-buddy/assets/1063891/7f4ae25c-d57f-464a-bd29-2261fc372688" alt="🚼 Bash Buddy"></a></div>

<p align="center">
<a href="https://www.apache.org/licenses/LICENSE-2.0.html"><img src="https://img.shields.io/github/license/foldright/bash-buddy?color=4D7A97&logo=apache" alt="License"></a>
<a href="https://github.com/foldright/bash-buddy/releases"><img src="https://img.shields.io/github/release/foldright/bash-buddy.svg" alt="GitHub release"></a>
<a href="https://github.com/foldright/bash-buddy/stargazers"><img src="https://img.shields.io/github/stars/foldright/bash-buddy" alt="GitHub Stars"></a>
<a href="https://github.com/foldright/bash-buddy/fork"><img src="https://img.shields.io/github/forks/foldright/bash-buddy" alt="GitHub Forks"></a>
<a href="https://github.com/foldright/bash-buddy/issues"><img src="https://img.shields.io/github/issues/foldright/bash-buddy" alt="GitHub issues"></a>
<a href="https://github.com/foldright/bash-buddy"><img src="https://img.shields.io/github/repo-size/foldright/bash-buddy" alt="GitHub repo size"></a>
</p>

🚼 Bash Buddy(aka. BaBy) contains `bash` libs and tools that extracted from `CI` scripts of my projects.

-----------------------------------

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [🗂 Lib](#-lib)
    - [`trap_error_info.sh`](#trap_error_infosh)
    - [`common_utils.sh`](#common_utilssh)
    - [`java_utils.sh`](#java_utilssh)
    - [`maven_utils.sh`](#maven_utilssh)
    - [`prepare_jdks.sh`](#prepare_jdkssh)
- [⚒️ Tool](#-tool)
    - [`gen_source_guard`](#gen_source_guard)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

-----------------------------------

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
    - `cu::print_calling_command_line`
    - `cu::die`

## [`java_utils.sh`](lib/javautils.sh)

java util functions.

api functions:

- `jvu::get_java_version`
- `jvu::switch_to_jdk`
- `jvu::java_cmd`

## [`maven_utils.sh`](lib/maven_utils.sh)

maven util functions for build.

api functions:

- maven operation functions:
    - `mvu::mvn_cmd`

## [`prepare_jdks.sh`](lib/prepare_jdks.sh)

a lib to prepare jdks by [sdkman](https://sdkman.io/).

api functions:

- `prepare_jdks::switch_to_jdk`
- `prepare_jdks::prepare_jdks`
- `prepare_jdks::install_jdk_by_sdkman`
- `prepare_jdks::load_sdkman`
- `prepare_jdks::install_sdkman`

# ⚒️ Tool

## [`gen_source_guard`](bin/gen_source_guard)

Generate source guard to bash lib scripts.

Example:

```sh
$ gen_source_guard
#_ source guard begin _#
[ -n "${__source_guard_0EDD6400_96EC_43E4_871A_E65F6781B828:+has_value}" ] && return
__source_guard_0EDD6400_96EC_43E4_871A_E65F6781B828=$(realpath -- "${BASH_SOURCE[0]}")
# the value of source guard is the canonical dir path of this script
readonly __source_guard_0EDD6400_96EC_43E4_871A_E65F6781B828=${__source_guard_0EDD6400_96EC_43E4_871A_E65F6781B828%/*}
#_ source guard end _#
```
