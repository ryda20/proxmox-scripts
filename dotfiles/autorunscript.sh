#!/bin/bash

# loop & print a folder recusively,
print_folder_recurse() {
    for f in "$1"/*;do
        if [ -d "${f}" ];then
            # recurse for directory
            print_folder_recurse "${f}"
        elif [ -f "${f}" ] ; then
			if [[ "$(basename -- ${f})" == "run_me.sh" ]] ; then
				# call it
				source "${f}"
			fi
        fi
    done
}

auto_run_scripts() {
	dir=${1:-/autorunscripts}
	if [ -d ${dir} ]; then
		# -exec bash will run script in new bash, so, not include all source of this current script like log, log_title,...
		# find ${dir} -type f -executable -name "run_me.sh" -exec bash {} \; -exec echo -e "Executed: {} \n" \;
		# but i want to use these functions in scripts inside autorunscripts directory,
		# so, using for and source command instead of find command 
		print_folder_recurse ${dir}	
	else
		log "autorunscripts not found!"
	fi
}

make_service() {
	
	local param=${1:-}
	local basename=$(basename $0)
	local service_path=/etc/systemd/system/autorunscripts.service
	echo "
[Unit]
Description=autorunscripts auto run user script
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

log_to /var/log/autorunscripts.log
log --title "autorunscript" "starting..."

auto_run_scripts "$@"

log --end
