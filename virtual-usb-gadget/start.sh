#!/bin/bash

CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"
# another default values
VID=0951
PID=1666
SERIAL="E0D55EA573FCF3A0F82B0466"
MANUF="Kingston"
PRODUCT="DataTraveler 3.0"

source "modules.sh"
source "usb_gadget.sh"

# usb_add_auto add from usb_list
usb_add_auto() {
	local name="${1}"
	local vid=${gg_vid[$name]}
	local pid=${gg_pid[$name]}
	local serial=${gg_serial[$name]}
	local manuf=${gg_manuf[$name]}
	local prod=${gg_prod[$name]}
	local bk_file=${gg_bf[$name]}
	#
	
	if [[ -d "${GADGET}/${name}" ]]; then
		echo "available usb gadget: $name."
		echo $(ls ${GADGET})
		usb_remove "${name}"
	fi
	usb_add "$name" "$vid" "$pid" "$serial" "$manuf" "$prod" "$bk_file"
}

usb_add_manual() {
	local name vid pid serial manuf prod bk_file

	echo "available gadget: " && ls "$GADGET/"
	read -e -i "g1" -p "Creating gadget directory? " name
	[[ -d "$GADGET/$name" ]] && read -e -i "n" -p "$name already exist. Do you want to override? [y/n]: " override
	if [[ "${override}" == "y" ]]; then
		read -e -i "n" -p "Do you want to remove backing file [y/n]? " rmbackingfile
		usb_remove "${name}" "${rmbackingfile}"
	fi
	read -e -i "$VID" -p "Enter Vendor ID: " vid
	read -e -i "$PID" -p "Enter Product ID: " pid
	read -e -i "$SERIAL" -p "Enter Serial: " serial
	read -e -i "$MANUF" -p "Enter Manufactor: " manuf
	read -e -i "$PRODUCT" -p "Enter Product: " prod
	read -e -p "Enter backing file path or type [dd | qemu] to create new one: " bk_file
	[[ "${bk_file}" == "dd" ]] && bk_file=$( new_backing_file_dd )
	[[ "${bk_file}" == "qemu" ]] && bk_file=$( new_backing_file_qemu_img )
	[[ ! -f "${bk_file}" ]] && echo "Not found ${bk_file}" && (exit 1) && return
	usb_add "$name" "$vid" "$pid" "$serial" "$manuf" "$prod" "$bk_file"
}


usb_remove_manual() {
	local name="${1}"
	[[ -z "${name}" ]] && echo "available gadget: " && ls "$GADGET/" && read -e -p "Enter USB gadget to stop: " name
	[[ ! -d "${GADGET}/${name}" ]] && echo -e "wrong gadget directory. availables:\n" && ls "${GADGET}/"
	read -e -i "n" -p "Do you want to remove backing file [y/n]? " rmbackingfile
	usb_remove "${name}" "${rmbackingfile}"
	echo "done!"
}

##### STARTING PROCESS #####
# check if user run this script with "static.sh" - config file for auto load
if [[ -f "$@" ]]; then
	# or auto running by config file
	source "$(pwd)/${1}"
	
	# set -e
	for name in "${gg_name[@]}"; do
		# echo "${gg_vid[@]}"
		echo "loading: name: ${name}, vid: ${gg_vid[$name]}, pid: ${gg_pid[$name]}, serial: ${gg_serial[$name]}, manuf: ${gg_manuf[$name]}, prod: ${gg_prod[$name]}, udc: ${gg_udc[$name]}, bk: ${gg_bf[$name]}"
		usb_add_auto "${name}"
	done
else
	msg="cmd(s): a: adding new usb \t r: remove usb \t i: available usbs/dummy_udc \t q: exit script"
	echo -e "${msg}"
	while true; do
		read -e -p "cmd: " answer
		case "$answer" in
			q) exit 0;;
			a)
				usb_add_manual
				[[ $? -gt 0 ]] && echo "add usb gadget got error -> consider to remove it" && usb_gadget_stop
				;;
			r)
				usb_remove_manual
				;;
			i)
				echo "#### udc(s) ####"
				ls /sys/class/udc
				echo "#### usb(s) gadget ####"
				ls ${GADGET}
				;;
			*)
				echo -e "${msg}"
		esac
	done
fi
