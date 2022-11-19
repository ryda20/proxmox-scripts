#!/bin/bash
source $(pwd)/modules.sh

_get_dummy_udc() {
	local list=$( ls /sys/class/udc/ )
	local list_used=$( find ${GADGET}/ -name UDC -exec cat {} \; )
	for x in $list; do
		if grep -q "$x" <<< "${list_used}"; then
			# echo "$x was used -> check another"
			continue
		else
			# $x can be use, so, return it
			echo "$x"
			return
		fi
	done
}


new_backing_file_dd() {
	read -e -p "where do you want to save backing file? " path
	[[ -z "${path}" ]] && echo "path can't empty. returning with error code " && ( exit 1 )
	read -e -p "how many megabyte do you want? " size
	[[ -z "${size}" ]] && echo "file size can't be empty. returning with error code" && ( exit 2 )
	dd bs=1M count=$((${size})) if=/dev/zero of="${path}"
	# allow math in size: 5 * 1024, ...
	echo "${path}"
}

new_backing_file_qemu_img() {
	read -e -p "where do you want to save backing file? " path
	[[ -z "${path}" ]] && echo "path can't empty. returning with error code " && ( exit 1 )
	read -e -p "size of image do you want?. use suffix M,G " size
	[[ -z "${size}" ]] && echo "file size can't be empty. returning with error code" && ( exit 2 )
	local filename=$(basename -- "${path}")
	local extension="${filename##*.}"
	qemu-img create -f ${extension} "${path}" "${size}" &> /dev/null # hide output of qemu-img
	echo "${path}"
}

usb_add() {
	local name="${1}"
	local vid=${2}
	local pid=${3}
	local serial=${4}
	local manuf=${5}
	local prod=${6}
	local bk_file=${7}
	local removable=${8:-1}
	local power=${9:-120}
	local stall=${10:-0}
	local cdrom=${11:-0}
	local nofua=${12:-1}
	echo "=> adding usb gadget: $name"
	# check required modules, using default values for dummy hcd
	usb_modules_load_auto
	#
	# 1. Create the gadget
	mkdir "$GADGET/${name}" && cd "$GADGET/${name}"
	[[ "${vid:0:2}" != "0x" ]] && vid="0x${vid}"
	echo ${vid} > idVendor
	[[ "${pid:0:2}" != "0x" ]] && pid="0x${pid}"
	echo ${pid} > idProduct
	mkdir strings/0x409 # Setting English strings
	echo ${serial} > strings/0x409/serialnumber
	echo ${manuf} > strings/0x409/manufacturer
	echo ${prod} > strings/0x409/product
	# 2. Creating the configurations
	mkdir configs/c.1
	mkdir configs/c.1/strings/0x409
	# echo "removable=1 iInterface=1 bInterval=255" > configs/c.1/strings/0x409/configuration
	echo ${power} > configs/c.1/MaxPower
	# 3. Creating the functions
	mkdir functions/mass_storage.0
	echo "${bk_file}" > functions/mass_storage.0/lun.0/file
	echo ${stall} > functions/mass_storage.0/stall
	echo ${removable} > functions/mass_storage.0/lun.0/removable
	echo ${cdrom} > functions/mass_storage.0/lun.0/cdrom
	echo ${nofua} > functions/mass_storage.0/lun.0/nofua
	## 4. Associating the functions with their configurations
	ln -s functions/mass_storage.0 configs/c.1
	## 5. Enabling the gadget
	local udc=$( _get_dummy_udc )
	if [[ -n "${udc}" ]]; then
		echo "${udc}" > UDC
		[[ $? -eq 0 ]] && echo "added usb gadget: ${name}" || echo "can't echo $udc to UDC"
	else 
		echo "not found any udc to active for gadget: $name"
		usb_remove ${name}
	fi
	
}

usb_remove() {
	local name=${1}
	local rmbackingfile=${2}
	#
	# 6. Disabling the gadget
	#
	echo "-> removing usb gadget: ${name}"
	if [[ ! -d "${GADGET}/${name}" ]] || [[ -z "${name}" ]]; then echo "not have usb gadget $name" && return; fi
	cd "${GADGET}/${name}"
	echo "" > UDC
	# echo "Remove functions from configurations was linked"
	rm -f configs/c.1/mass_storage.0
	# echo "Cleaning up configuration dir"
	rmdir configs/c.1/strings/0x409
	rmdir configs/c.1
	[[ "$rmbackingfile" == "y" ]] && rm -f "$( cat functions/mass_storage.0/lun.0/file )"
	# echo "removing functions/mass_storage.0"
	rmdir functions/mass_storage.0
	# echo "Clearing English strings"
	rmdir strings/0x409
	# echo "Removing gadget directory"
	cd $GADGET
	rmdir ${name}
	echo "=> removed usb gadget: $name"
	# check and remove loaded modules if does not exist any usb gadget
	usb_modules_remove_auto
}
