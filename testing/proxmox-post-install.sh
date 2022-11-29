#!/bin/bash

[[ -z "$(which curl)" ]] && apt install -y curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"

log --title "Update Proxmox" "proxmox updating..."
log "disable proxmox enterprise repos"
sed -i 's|^deb http://download.proxmox.com|#&|' /etc/apt/sources.list
sed -i 's|^deb https://enterprise|#&|' /etc/apt/sources.list.d/pve-enterprise.list
apt update 
apt upgrade


log --title "Local Volumn Edit" "delete local lvm and enable local size to maximum"
# read -p "Delete local-lvm (lvm-thin) volumn [y/n]: " answer
# [[ "${answer}" == "y" ]] && lvremove /dev/pve/data
lvremove /dev/pve/data
log "deleted local volumn: /dev/pve/data.\n pls delete local-lvm in admin web GUI, too (datacenter > Storage > local-lvm -> Remove"
log "resize lvm to maximize free disk space"
# read -p "resize local lvm (lvm) to maximum [y/n]: " answer
# [[ "${answer}" == "y" ]] && lvresize -l +100%FREE /dev/pve/root
lvresize -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root

log --title "Enable IOMMU" "Enabling Intel IOMMU"
# for intel: 	intel_iommu=on
# for amd: 		amd_iommu=on
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on /' /etc/default/grub
update-grub
#

echo -e "vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd" >> /etc/modules

echo "options vfio_iommu_type1 allow_unsafe_interrupts=1" > /etc/modprobe.d/iommu_unsafe_interrupts.conf
echo "options kvm ignore_msrs=1" > /etc/modprobe.d/kvm.conf
log "adding gpu to blacklist"
echo "blacklist radeon" >> /etc/modprobe.d/blacklist.conf 
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf 
echo "blacklist nvidia" >> /etc/modprobe.d/blacklist.conf 

# after reboot, you can check with this command
echo "Restart computer required"
dmesg | grep -e DMAR -e IOMMU






# -Configure GPU for PCIe Passthrough-

# 	- Find your GPU
# lspci -v

# 	- Enter the PCI identifier
# lspci -n -s 82:00

# 	- Copy the HEX values from your GPU here:
# echo "options vfio-pci ids=####.####,####.#### disable_vga=1"> /etc/modprobe.d/vfio.conf

# update-initramfs -u
