#!/bin/bash

#### FileBrowser
# https://filebrowser.org
# https://github.com/filebrowser/filebrowser

make_service() {
	
	local rootdir=${1:-} # $1: define running in proxmox server or vm
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
ExecStart=filebrowser -r $rootdir
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

## starting ##
[[ -z "$(which curl)" ]] && apt install -y curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"


curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

mkdir /rootdir
make_service "/rootdir"
