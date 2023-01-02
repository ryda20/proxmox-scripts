#!/bin/bash

root_required() {
	# Abort if not executed as root.
	if [[ $(id -u) != "0" ]]; then
		echo "root privilege required"
		exit 1
	fi
}

root_required
