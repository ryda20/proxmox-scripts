#!/bin/bash

tensorflow() {
	# make temp directory as working dir
	currentdir=$(pwd) && dir=`mktemp -d` && cd $dir

	# install tensorlow
	AVX=$(grep -o -m1 'avx[^ ]*' /proc/cpuinfo)
	if [[ "$AVX" =~ avx2 ]]; then
		wget https://dl.photoprism.org/tensorflow/linux/libtensorflow-linux-avx2-1.15.2.tar.gz
		tar -C /usr/local -xzf libtensorflow-linux-avx2-1.15.2.tar.gz
	elif [[ "$AVX" =~ avx ]]; then
		wget https://dl.photoprism.org/tensorflow/linux/libtensorflow-linux-avx-1.15.2.tar.gz
		tar -C /usr/local -xzf libtensorflow-linux-avx-1.15.2.tar.gz
	else
		wget https://dl.photoprism.org/tensorflow/linux/libtensorflow-linux-cpu-1.15.2.tar.gz
		tar -C /usr/local -xzf libtensorflow-linux-cpu-1.15.2.tar.gz
	fi
	ldconfig

	cd $currentdir && rm -r $dir
}
