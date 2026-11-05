#!/bin/zsh

setopt ERR_EXIT NO_UNSET PIPE_FAIL

readonly version="0.1.0-dev"

function show_help {
	print -r -- "usage: zshbundle <command>

Commands:
	help, --help, -h	Show this help
	version, --version	Show the version"
}

function main {
	if (($# != 1)); then
		show_help
		return 0
	fi

	case "$1" in
	help | --help | -h)
		show_help
		;;
	version | --version)
		print -r -- $version
		;;
	*)
		print -r -u2 -- "Unknown command: $1"
		return 1
		;;
	esac
}

main "$@"
