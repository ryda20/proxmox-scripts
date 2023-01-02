#!/bin/bash

nodejs() {
	local version
	while [[ $# -gt 0 ]]; do
		case $1 in 
		-v | --version)
			shift; version="$1";;
		*)
			echo "Unknow flag $1" && return;;
		esac
		shift
	done
	# default values
	version="${version:-"current.x"}"
	curl -sL https://deb.nodesource.com/setup_${version} | bash -
	apt install -y nodejs
}
