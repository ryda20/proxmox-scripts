#!/bin/bash

apk add --no-cache curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"
