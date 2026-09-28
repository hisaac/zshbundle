#!/usr/bin/env zsh

setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly tests_directory="${0:A:h}"

actual_output="$(zsh -f "${tests_directory}/fixtures/greeting/main.zsh")"

if [[ "$actual_output" != "Hello, world!" ]]; then
	print -r -u2 -- "FAIL: unexpected greeting: ${actual_output}"
	exit 1
fi

temporary_directory="$(mktemp -d)"
readonly temporary_directory

trap 'rm -rf -- "$temporary_directory"' EXIT

cp -R \
	"${tests_directory}/fixtures/greeting" \
	"${temporary_directory}/greeting"

zsh -f \
	"${tests_directory}/../src/main.zsh" \
	"${temporary_directory}/greeting/main.zsh" \
	>"${temporary_directory}/bundle.zsh"

# Remove the copied sources to prove the bundle is self-contained.
rm -rf -- "${temporary_directory}/greeting"

zsh -f -n "${temporary_directory}/bundle.zsh"

actual_output="$(zsh -f "${temporary_directory}/bundle.zsh")"

if [[ "$actual_output" != "Hello, world!" ]]; then
	print -r -u2 -- "FAIL: unexpected bundled greeting: ${actual_output}"
	exit 1
fi

print -r -- "PASS: greeting bundle"
