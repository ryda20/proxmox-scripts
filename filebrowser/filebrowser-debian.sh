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
WorkingDirectory=$HOME/.filebrowser
#ExecStartPre=
ExecStart=filebrowser \"$@\"
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
	local address cachedir config database port rootdir password
	while [[ $# -gt 0 ]]; do
		case $1 in 
		-p|--password)
			shift; password="$1";;
		-a|--address)
			shift; address="$1";;
		-p|--port)
			shift; port="$1";;
		# --cache-dir)
		# 	shift; cachedir="$1";;
		-c|--config)
			shift; config="$1";;
		-d|--database)
			shift; database="$1";;
		-r|--root)
			shift; rootdir="$1";;
		*)
			echo "";;
		esac
		shift
	done
	# default values
	password="${password:-admin}"
	address="${address:-0.0.0.0}"
	port="${port:-1523}"
	# cachedir="${cachedir:-}"
	config="${config:-$HOME/.filebrowser/filebrowser.yaml}"
	database="${database:-$HOME/.filebrowser/filebrowser.db}"
	rootdir="${rootdir:-/rootdir}"

	#
	mkdir -p "$rootdir"
	mkdir -p "$HOME/.filebrowser"

	#
	log "stop it first"
	systemctl stop filebrowser
	#
	log "download and install"
	curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

	# check
	[[ -z "$(which filebrowser)" ]] && log --error "install FileBrowser not successfull" && exit 1
	#
	log "cd to $HOME/.filebrowser"
	cd $HOME/.filebrowser
	#
	log "create config file first time"
	filebrowser config init
	#
	log "change somme important values"
	filebrowser config set --log /var/log/filebrowser.log
	filebrowser config set --address $address --port $port
	filebrowser config set --database $database
	filebrowser config set --root $rootdir
	log "create admin user..."
	filebrowser users add admin $password --perm.admin
	# [[ -n "$cachedir" ]] && filebrowser config set --cache-dir $cachedir

	log "export config file to: $config"
	filebrowser config export $config
	# filebrowser config set --config $config

	log "make a service file"
	make_service "-c $config"

	# log "generate options: $HOME/.filebrowser/filebrowser.yaml"
	log "default username and password is: admin"
	log "database: $database"
	log "rootdir: $rootdir"
	log "listen on: $address:$port"
	log "default username: admin, password: $password"
}

## starting ##
[[ -z "$(which curl)" ]] && apt install -y curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"
main "$@"
