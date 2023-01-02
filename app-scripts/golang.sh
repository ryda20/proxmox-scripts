#!/bin/bash

golang() {
	local version
	while [[ $# -gt 0 ]]; do
		case $1 in 
		-v | --verion)
			shift; version="$1";;
		*)
			echo "Unknow flag $1" && return;;
		esac
		shift
	done
	# default values
	version="${version:-"1.19.3"}"
	# make temp directory as working dir
	dir=`mktemp -d` && cd $dir

	# install golang
	rm -rf /usr/local/go
	wget https://golang.org/dl/go${version}.linux-amd64.tar.gz
	tar -xzf go${version}.linux-amd64.tar.gz -C /usr/local
	ln -s /usr/local/go/bin/go /usr/local/bin/go

	# cleanup
	cd ~ && rm -r $dir
}
