#!/bin/bash

root_required() {
	# Abort if not executed as root.
	if [[ $(id -u) != "0" ]]; then
		echo "Usage: run ${0##*/} as root" 1>&2
		exit 1
	fi
}

root_required
