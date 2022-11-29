#!/bin/bash

echo "#### DELETE LOCAL LVM AND ENABLE LOCAL SIZE ####"
# read -p "Delete local-lvm (lvm-thin) volumn [y/n]: " answer
# [[ "${answer}" == "y" ]] && lvremove /dev/pve/data
lvremove /dev/pve/data
echo "delete local-lvm in admin web GUI, too (datacenter > Storage > local-lvm -> Remove"
#
# read -p "resize local lvm (lvm) to maximum [y/n]: " answer
# [[ "${answer}" == "y" ]] && lvresize -l +100%FREE /dev/pve/root
lvresize -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root

echo "#### ENABLE IOMMU ####"
echo -e "vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd" >> /etc/modules
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="intel_iommu=on /' /etc/default/grub
update-grub
proxmox-boot-tool refresh
# update-initramfs -u -k all
dmesg | grep -e DMAR -e IOMMU
echo "Restart computer required"


echo "#### DISABLED PROXMOX ENTERPRISE REPOS ####"
sed -i 's|deb https://enterprise|#deb https://enterprise|' /etc/apt/sources.list.d/pve-enterprise.list
apt update 
apt upgrade
