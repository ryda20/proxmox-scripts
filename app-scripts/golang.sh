#!/bin/bash


golang() {
	# cleanup, move to caller directory
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
	currentdir=$(pwd) && dir=`mktemp -d` && cd $dir

	echo "download and install golang ${version}"
	rm -rf /usr/local/go
	wget https://golang.org/dl/go${version}.linux-amd64.tar.gz
	tar -xzf go${version}.linux-amd64.tar.gz -C /usr/local
	ln -s /usr/local/go/bin/go /usr/local/bin/go

	cd $currentdir && rm -r $dir
}
