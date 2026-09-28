#!/usr/bin/env zsh

readonly tests_directory="${0:A:h}"
source "${tests_directory}/../scripts/lib/common.zsh" || exit 1

typeset -i passed=0 failed=0

function run_test {
	readonly name="$1"
	shift

	# Tests check failures explicitly because this conditional disables ERR_EXIT.
	if "$@"; then
		log_info "PASS: ${name}"
		((++passed))
	else
		log_error "FAIL: ${name}"
		((++failed))
	fi
}

function test_greeting_fixture {
	local actual_output
	actual_output="$(zsh -f "${tests_directory}/fixtures/greeting/main.zsh")" || return $?

	if [[ "$actual_output" != "Hello, world!" ]]; then
		log_error "Unexpected greeting: ${actual_output}"
		return 1
	fi
	return 0
}

function test_greeting_bundle {
	readonly working_directory="$1"
	local actual_output

	cp -R \
		"${tests_directory}/fixtures/greeting" \
		"${working_directory}/greeting" || return $?

	zsh -f \
		"${PROJECT_ROOT}/src/main.zsh" \
		"${working_directory}/greeting/main.zsh" \
		>"${working_directory}/bundle.zsh" || return $?

	# Remove the copied sources to prove the bundle is self-contained.
	rm -rf -- "${working_directory}/greeting" || return $?

	zsh -f -n "${working_directory}/bundle.zsh" || return $?

	actual_output="$(zsh -f "${working_directory}/bundle.zsh")" || return $?

	if [[ "$actual_output" != "Hello, world!" ]]; then
		log_error "Unexpected bundled greeting: ${actual_output}"
		return 1
	fi
	return 0
}

temporary_directory="$(mktemp -d)"
readonly temporary_directory
trap 'rm -rf -- "$temporary_directory"' EXIT

run_test "greeting fixture" test_greeting_fixture
run_test "greeting bundle" test_greeting_bundle "$temporary_directory"

log_info "${passed} passed, ${failed} failed"
if ((failed > 0)); then
	exit 1
fi
