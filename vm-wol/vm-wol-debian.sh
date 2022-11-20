#!/bin/bash

[[ -z "$(which curl)" ]] && apt install -y curl

source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"


vm_waiting_wakeonlan_signal() {
	local listener_port=${1:-9}
	local server_listener_port=${2:-9}
	local server_listener_addr=${3:-192.168.0.100}
	local received
	while true; do
		log "listing on UDP port: $listener_port..."
		received="$(echo 'RDTEMP1' | nc -ul -p $listener_port -q 0.1)"
		log "got wakeonlan signal:\n$received"
		log "send to server node port: $server_listener_port"
		# using -q 0 to exit netcat after send data
		echo "${received}" | nc -q 0.1 ${server_listener_addr} ${server_listener_port} 
	done
}




proxmox_qm_get_all_vm_id() {
	# get list of all vm
	# then, tr -s ' ': 	# replace each sequence of a repeated character
                        # that is listed in the last specified SET,
                        # with a single occurrence of that character
	# then, cut -d ' ' -f 2: print column 2 (-f 2) after cut with delimiter (-d ' ')
	# to get out VMID column
	vmid_column="$( qm list | tr -s ' ' | cut -d ' ' -f 2 )"
	echo "$vmid_column"
}



proxmox_received_mac_addr() {
	local listener_port=${1:-9}
	# received value from client (guacamole machine or what ever listing on 54321)
	received="$(echo 'RDTEMP1' | nc -l -p $listener_port)"
	# send received value to stdbuf, filted and get unique value
	# then, modify buffer by stdbuf
	#	-o0: adjust standar output stream buffering mode 0
	#		 If MODE is '0' the corresponding stream will be unbuffered
	# 	then run command xxd (make a hexdump or do the reverse)
	#		-c cols | -cols cols
	#			Format <cols> octets per line. Default 16 (-i: 12, -ps: 30, -b: 6). Max 256.
	# 		-p | -ps | -postscript | -plain
    #   		Output in postscript continuous hexdump style. Also known as plain hexdump style.
	# then, remove all duplicate with command uniq from stdbug
	x="$(echo "$received" | stdbuf -o0 xxd -c 6 -p | stdbuf -o0 uniq)"
	# using grep to remove unnecessary thing, and we only have again mac address, look like: 4574a4420f02
	# with from sending: "45:74:A4:42:0F:02"
	x=`echo "$x" | grep -v 'ffffffffffff' | grep -v '0a'`
    # mac address in string without ":"
	echo "$x"
}

proxmox_main() {
	local re='^[0-9]+$'
	local macWOL
	local netx
	local LISTEN_PORT=9
	log "listining on port: $LISTEN_PORT"
	# passing received mac address to while read and converto to original mac address format
	proxmox_received_mac_addr $LISTEN_PORT | while read; do
		macWOL="${REPLY:0:2}:${REPLY:2:2}:${REPLY:4:2}:${REPLY:6:2}:${REPLY:8:2}:${REPLY:10:2}"
        log "received macWOL: $macWOL"
        macWOL=`echo "$macWOL" | tr "[:upper:]" "[:lower:]"`
		# get vm id(s) and check for each one to see if it valid id, then from id, we can get vm config
		# then, from vm config, we can get mac address with line start with: 'net0'
		proxmox_qm_get_all_vm_id | while read -r id; do
			if [[ $id =~ $re ]] ; then
                log  "check VM-ID $id for $macWOL"
				netx=`qm config $id | grep ^net`
                echo "$netx" | while read -r macstr ; do
                    macstr=`echo "$macstr" | tr "[:upper:]" "[:lower:]"`
                    if [[ $macstr == *"$macWOL"* ]]; then
                        log "found vm id: $id with mac address: $macWOL -> starting it now..."
						local vm_status=`qm status $id`
						# status: running
						# status: stopped
						if [[ " $vm_status " == *" stopped "* ]]; then
							qm start $id
						else
							echo "vm: $id status: $vm_status"
						fi
						break 3
                    fi
                done
            fi
		done
	done
}


make_service() {
	
	local param=${1:-} # $1: define running in proxmox server or vm
	local basename=$(basename $0)
	local service_path=/etc/systemd/system/proxmox-vm-wol.service
	echo "
[Unit]
Description=Proxmox VM wake on lan script
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
	systemctl start proxmox-vm-wol
	systemctl status proxmox-vm-wol
	log "enable start at boot"
	systemctl enable proxmox-vm-wol
}

## starting ##
## install for vm: ./vm-wol.sh install vm
## install for proxmox server: ./vm-wol.sh install
cmd="${1}"
param="${2}"
if [[ "$cmd" == "install" ]]; then
	
	make_service $param

elif [[ "$cmd" == "vm" ]]; then
	
	log "starting script in vm"
	while true; do
		vm_waiting_wakeonlan_signal
	done

else
	log "starting script in proxmox server"
	[[ -z "$(which qm)" ]] && echo "not found qm command on this server. using \"${0} vm\" to run in vm machine" && exit 1
	while true; do
		proxmox_main
	done
fi
