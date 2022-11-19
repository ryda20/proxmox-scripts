#!/bin/bash

#### INSTALLATION ####==============================================================================================
# add to vm id 100 using command below
# qm set 100 --hookscript local:snippets/virtual-gadget-usb-snippets.sh
####================================================================================================================
#### Requirements ####==============================================================================================
# virtual-usb-gadget repository downloaded to /root/virtual-usb-gadget
# raw-gadget repository downloaded to /root/raw-gadget and compiled dummy_hcd
####================================================================================================================
#### Variables ####=================================================================================================
declare -A gg_name
gg_name[0]=unRAIDbkServer
#
declare -A gg_bf
gg_bf[unRAIDbkServer]="/var/lib/vz/images/100/vm-100-disk-0.raw"
gg_bf[g2]=/root/usb1.raw
gg_bf[g3]=/root/usb2.raw
#
declare -A gg_vid
gg_vid[unRAIDbkServer]=0x0951
#
declare -A gg_pid
gg_pid[unRAIDbkServer]=0x1666
#
declare -A gg_serial
gg_serial[unRAIDbkServer]=E0D55EA573FCF3A0F82B0467
#
declare -A gg_manuf
gg_manuf[unRAIDbkServer]=Kingston
#
declare -A gg_prod
gg_prod[unRAIDbkServer]="DataTraveler 3.0"
#
####================================================================================================================
#### Functions ####=================================================================================================
vug_start() {
	local name vid pid serial manuf prod bk_file
	for name in "${gg_name[@]}"; do
		#name="${1}"
		vid=${gg_vid[$name]}
		pid=${gg_pid[$name]}
		serial=${gg_serial[$name]}
		manuf=${gg_manuf[$name]}
		prod=${gg_prod[$name]}
		bk_file=${gg_bf[$name]}
		
		echo "loading: name: ${name}, vid: ${gg_vid[$name]}, pid: ${gg_pid[$name]}, serial: ${gg_serial[$name]}, manuf: ${gg_manuf[$name]}, prod: ${gg_prod[$name]}, udc: ${gg_udc[$name]}, bk: ${gg_bf[$name]}"
		# remove first if exist
		[[ -d "${GADGET}/${name}" ]] && usb_remove "${name}"
		#
		usb_add "$name" "$vid" "$pid" "$serial" "$manuf" "$prod" "$bk_file"
	done
}
####================================================================================================================
#### STARTING PROCESS ####==========================================================================================
source /root/proxmox-scripts/virtual-usb-gadget/usb_gadget.sh
vug_start
#### FUNTIONS ####==================================================================================================
####================================================================================================================
