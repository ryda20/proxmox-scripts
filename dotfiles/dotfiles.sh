#!/bin/bash

auto_link_dotfiles() {
	dir=${1:-/dotfiles}
	home=${2:-~}
	if [ -d ${dir} ] ; then
		# loop for hidden file .xxxx, not ..xxxx, * does not match with dot (.)
		for f in ${dir}/.[^.]* ; do
			fileName=$(basename ${f})
			linkedName=${home}/${fileName}  # file in home directory of current user
			#
			log "-> linking ${f} -> ${linkedName}"
			# f: remove symbolic if it exist and a file
			# n: remove symbolic if it exist and a directory 
			ln -sfn ${f} ${linkedName}
		done
	fi
}

make_service() {
	
	local param=${1:-}
	local basename=$(basename $0)
	local service_path=/etc/systemd/system/dotfiles.service
	echo "
[Unit]
Description=dotfiles script - auto link all dotfiles mounted at /dotfiles to ~ of the user
Documentation=https://github.com/ryda20/proxmox-scripts

[Service]
Type=simple
User=root
Group=root
TimeoutStartSec=0
Restart=on-failure
RestartSec=30s
#ExecStartPre=
ExecStart=$(pwd)/$basename $param
SyslogIdentifier=Diskutilization
#ExecStop=

[Install]
WantedBy=multi-user.target
	" > $service_path

	systemctl daemon-reload
	log "starting.."
	systemctl start dotfiles
	systemctl status dotfiles
	log "enable start at boot"
	systemctl enable dotfiles
}

## starting ##
[[ -z "$(which curl)" ]] && apt install -y curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"

log_to /var/log/dotfiles.log
log --title "dotfiles" "starting..."
auto_link_dotfiles "$@"
log --end
