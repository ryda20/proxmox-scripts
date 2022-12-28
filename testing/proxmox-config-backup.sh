#!/bin/bash

# exit on error
set -e

#get backup dir from env or using default value here
BACKUP_DIR="${PS_BACKUP_DIR:-/mnt/pve/unRAID-proxmox/backup}"
_bdir=$BACKUP_DIR

MAX_BACKUPS=5
_tdir=/tmp/proxmox-config-backup
rm -r $_tdir | true
mkdir -p $_tdir

# Don't change if not required
_now=$(date +%Y-%m-%d.%H.%M.%S)
_HOSTNAME=$(hostname -f)
_filename1="$_tdir/proxmoxetc.$_now.tar"
_filename2="$_tdir/proxmoxpve.$_now.tar"
_filename3="$_tdir/proxmoxroot.$_now.tar"
_filename4="$_tdir/proxmoxcron.$_now.tar"
_filename5="$_tdir/proxmoxvbios.$_now.tar"
_filename6="$_tdir/proxmoxpackages.$_now.list"
_filename7="$_tdir/proxmoxreport.$_now.txt"
_filename8="$_tdir/proxmoxlocalbin.$_now.tar"
_filename_final="$_tdir/proxmox_backup_"$_HOSTNAME"_"$_now".tar.gz"


# Set terminal to "dumb" if not set (cron compatibility)
export TERM=${TERM:-dumb}


clean_up () {
    exit_code=$?
    echo "Cleaning up"
    rm -rf $_tdir
}

# register the cleanup function to be called on the EXIT signal
trap clean_up EXIT


##########

function description {
# Check to see if we are in an interactive terminal, if not, skip the description
    if [[ -t 0 && -t 1 ]]; then
        clear
        cat <<EOF

        Proxmox Scripts Backup Config
        Hostname: "$_HOSTNAME"
        Timestamp: "$_now"

        Files to be saved:
        "/etc/*, /var/lib/pve-cluster/*, /root/*, /var/spool/cron/*, /usr/share/kvm/*.vbios"

        Backup target:
        "$BACKUP_DIR"
        -----------------------------------------------------------------
        This script is will backup configuration of proxmox server and not VM
        or LXC container data!
        -----------------------------------------------------------------

        Hit return to proceed or CTRL-C to abort.
EOF
        read dummy
        clear
    fi
}

function root_check {
    if [[ ${EUID} -ne 0 ]] ; then
        echo "root require" ; exit 1
    fi
}

function check-num-backups {
    if [[ $(ls ${_bdir}/*${_HOSTNAME}*.tar.gz -l | grep ^- | wc -l) -ge $MAX_BACKUPS ]]; then
        local oldbackup="$(basename $(ls ${_bdir}/*${_HOSTNAME}*.tar.gz -t | tail -1))"
        echo "${_bdir}/${oldbackup}"
        rm "${_bdir}/${oldbackup}"
    fi
}

function copyfilesystem {
    echo "Tar files"
    # copy key system files
    tar --warning='no-file-ignored' -cvPf "$_filename1" /etc/.
    tar --warning='no-file-ignored' -cvPf "$_filename2" /var/lib/pve-cluster/.
    tar --warning='no-file-ignored' -cvPf "$_filename3" /root/.
    tar --warning='no-file-ignored' -cvPf "$_filename4" /var/spool/cron/.

    if [ "$(ls -A /usr/local/bin 2>/dev/null)" ]; then
        tar --warning='no-file-ignored' -cvPf "$_filename8" /usr/local/bin/.; 
    fi

    if [ "$(ls /usr/share/kvm/*.vbios 2>/dev/null)" != "" ] ; then
	    echo backing up custom video bios...
	    tar --warning='no-file-ignored' -cvPf "$_filename5" /usr/share/kvm/*.vbios
    fi
    # copy installed packages list
    echo "Copying installed packages list from APT"
    apt-mark showmanual | tee "$_filename6"
    # copy pvereport output
    echo "Copying pvereport output"
    pvereport | tee "$_filename7"
}

function compressandarchive {
    echo "Compressing files"
    # archive the copied system files
    tar -cvzPf "$_filename_final" $_tdir/*.{tar,list,txt}

    # copy config archive to backup folder
    # this may be replaced by scp command to place in remote location
    cp $_filename_final $_bdir/
}

function stopservices {
    # stop host services
    for i in pve-cluster pvedaemon vz qemu-server; do systemctl stop $i ; done
    # give them a moment to finish
    sleep 10s
}

function startservices {
    # restart services
    for i in qemu-server vz pvedaemon pve-cluster; do systemctl start $i ; done
    # Make sure that all VMs + LXC containers are running
    qm startall
}

##########

description
root_check
check-num-backups

# We don't need to stop services, but you can do that if you wish
#stopservices

copyfilesystem

# We don't need to start services if we did not stop them
#startservices

compressandarchive
