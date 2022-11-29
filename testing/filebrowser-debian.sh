#!/bin/bash

#### FileBrowser
# https://filebrowser.org
# https://github.com/filebrowser/filebrowser

make_service() {
	
	local paras="$@"
	local basename=$(basename $0)
	local service_name=filebrowser
	local service_path=/etc/systemd/system/${service_name}.service
	echo "
[Unit]
Description=FileBrowser
Documentation=https://github.com/filebrowser/filebrowser

[Service]
Type=simple
User=root
Group=root
TimeoutStartSec=0
Restart=on-failure
RestartSec=30s
#ExecStartPre=
ExecStart=filebrowser "$@"
SyslogIdentifier=Diskutilization
#ExecStop=

[Install]
WantedBy=multi-user.target
" > $service_path

	systemctl daemon-reload
	log "starting.."
	systemctl start ${service_name}
	systemctl status ${service_name}
	log "enable start at boot"
	systemctl enable ${service_name}
}

main() {
	local args=("$@")
	local address cachedir config database port rootdir
	while [[ $# -gt 0 ]]; do
		case $1 in 
		--address|-a)
			shift; address="$1";;
		--port|-p)
			shift; port="$1";;
		--cache-dir)
			shift; cachedir="$1";;
		--config|-c)
			shift; config="$1";;
		--database|-d)
			shift; database="$1";;
		--root|-r)
			shift; rootdir="$1";;
		*)
			echo "";;
		esac
		shift
	done

	log "download and install"
	curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash


	# default values
	address="${address:-0.0.0.0}"
	port="${port:-1523}"
	cachedir="${cachedir:-}"
	config="${config:-}"
	database="${database:-$HOME/.filebrowser/filebrowser.db}"
	rootdir="${rootdir:-/rootdir}"
	#
	mkdir -p "$rootdir"
	mkdir -p "$HOME/.filebrowser"
	#
	local params="--address \"$address\" --port \"$port\" --cache-dir \"$cachedir\" --database \"$database\" --root \"$rootdir\""
	[[ -n "$config" ]] && params="--config \"$config\" $params"
	make_service "$params"

	# log "generate options: $HOME/.filebrowser/filebrowser.yaml"
	log "default username and password is: admin"
	log "database: $database"
	log "rootdir: $rootdir"
	log "listen on: $address:$port"
}

## starting ##
[[ -z "$(which curl)" ]] && apt install -y curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"

main "$@"
