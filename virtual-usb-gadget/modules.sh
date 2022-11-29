#!/bin/bash

CONFIGFS="/sys/kernel/config"
GADGET="$CONFIGFS/usb_gadget"
# another default values
VID=0951
PID=1666
SERIAL="E0D55EA573FCF3A0F82B0466"
MANUF="Kingston"
PRODUCT="DataTraveler 3.0"

# location of the compiled dummy_hcd
DUMMY_HCD_MOD=$(pwd)/raw-gadget/dummy_hcd/dummy_hcd.ko
# number of usb you can create and use, max 32
DUMMY_HCD_INSTANCES=10
# speed: super speed - USB3, high speed - USB2, else: USB1.1
DUMMY_HCD_SPEED="is_super_speed=1"

ALLOW_RELOAD_DUMMY_HCD=no
ALLOW_REMOVE_MODULES=yes

usb_modules_load() {
	# NOTE: can add directly to /etc/modules
	[[ -z "$( lsmod | grep "libcomposite" )" ]] && modprobe -v libcomposite
	[[ -z "$( lsmod | grep "udc_core" )" ]] && modprobe -v udc_core
	[[ -z "$( lsmod | grep "usb_f_mass_storage" )" ]] && modprobe -v usb_f_mass_storage
	[[ ! -d "${GADGET}" ]] && mount none $CONFIGFS -t configfs &> /dev/null
	[[ -z "$( lsmod | grep "dummy_hcd" )" ]] && insmod ${DUMMY_HCD_MOD} num=${DUMMY_HCD_INSTANCES} ${DUMMY_HCD_SPEED} && [[ "$?" -gt 0 ]] && echo "cmd: insmod ${DUMMY_HCD_MOD} num=${DUMMY_HCD_INSTANCES} ${DUMMY_HCD_SPEED}"
}

usb_modules_remove() {
	rmmod -v dummy_hcd
	modprobe -r -v usb_f_mass_storage
	modprobe -r -v udc_core
	modprobe -r -v libcomposite
}

usb_modules_load_auto() {
	# check and auto increase (reload dummy_hcd) instances
	local available_usb=()
	local available_udc=()
	[[ -d "${GADGET}" ]] && available_usb=( $(ls "${GADGET}") )
	[[ -d "/sys/class/udc" ]] && available_udc=( $( ls /sys/class/udc ) )
	if [[ ${#available_udc[@]} -eq 0 ]]; then
		# load for the first time
		usb_modules_load
	elif [[ "${ALLOW_RELOAD_DUMMY_HCD}" == "yes" ]] && [[ ${#available_udc[@]} -le ${#available_usb[@]} ]]; then
		#  de-active usb and remove dummy_udc
		if [[ -n "$( lsmod | grep "dummy_hcd" )" ]]; then
			echo "de-active usb gadget before rm module"
			for dir in $( ls "${GADGET}/" ); do
				echo "deactive: ${dir}"
				echo "" > "${GADGET}/${dir}/UDC"
			done
			# remove module
			rmmod -v "dummy_hcd"
		fi
		# install dummy_udc again
		local dummy_hcd_instance=$(( ${#available_usb[@]} + 1 ))
		[[ ${dummy_hcd_instance} -gt 32 ]] && dummy_hcd_instance=32
		insmod ${dummy_hcd} num=${dummy_hcd_instance} ${speed}
		# show message if got error
		[[ "$?" -gt 0 ]] && echo "cmd: insmod ${dummy_hcd} num=${dummy_hcd_instance} ${speed}"
		# active usb again
		echo "re-active usb gadget after reload module"
		for dir in $( ls "${GADGET}/" ); do
			echo "active: ${dir}"
			local udc=$( _get_dummy_udc )
			echo "${udc}" > "${GADGET}/${dir}/UDC"
		done
	fi
}
usb_modules_remove_auto() {
	## auto remove base on usb
	# check and auto increase (reload dummy_hcd) instances
	local available_usb=($( ls ${GADGET} )) # return array
	if [[ "${ALLOW_REMOVE_MODULES}" == "yes" ]] && [[ ${#available_usb[@]} -lt 1 ]]; then
		usb_modules_remove
	fi
}

### starting here ###
# if [[ "${@}" == "remove" ]]; then
# 	usb_modules_remove
# else
# 	usb_modules_load
# fi
