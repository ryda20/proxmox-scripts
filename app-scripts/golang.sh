#!/bin/bash

golang() {
	local version
	while [[ $# -gt 0 ]]; do
		case $1 in 
		-v | --version)
			shift; version="$1";;
		*)
			echo "Unknow flag $1" && exit 1;;
		esac
		shift
	done
	# default values
	version="${version:-"1.19.3"}"
	# make temp directory as working dir
	dir=`mktemp -d` && cd $dir

	echo "download and install golang ${version}"
	rm -rf /usr/local/go
	wget https://golang.org/dl/go${version}.linux-amd64.tar.gz
	tar -xzf go${version}.linux-amd64.tar.gz -C /usr/local
	ln -s /usr/local/go/bin/go /usr/local/bin/go

	# cleanup, move to caller directory
	echo "The script you are running has basename $( basename -- "$0"; ), dirname $( dirname -- "$0"; )";
	echo "The present working directory is $( pwd; )";
	exit
	cd $SCRIPT_DIR && rm -r $dir
}
