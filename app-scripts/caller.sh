#!/bin/bash

caller_script() {
	echo $(realpath "$0")
}

caller_dir() {
	SCRIPT=$(realpath "$0")
	DIRNAME=$( dirname -- $SCRIPT )
	echo $DIRNAME
}

caller_name() {
	SCRIPT=$(realpath "$0")
	BASENAME=$( basename -- $SCRIPT )
	echo $BASENAME
}
