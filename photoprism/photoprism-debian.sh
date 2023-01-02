#!/bin/bash

dependences() {
	# install depending
	apt install -y git curl gcc g++ gnupg make zip unzip exiftool ffmpeg
	# file converter tools: 
	# https://docs.photoprism.app/getting-started/config-options/#file-converters
	apt install -y darktable rawtherapee rawtherapee-data libheif-examples
}

darktable() {
	root_required
	#
	SYSTEM_ARCH=$(uname -m)
	#
	. /etc/os-release
	echo "Installing Darktable for ${SYSTEM_ARCH^^}..."
	#
	case $SYSTEM_ARCH in
	amd64 | AMD64 | x86_64 | x86-64)
		if [[ $VERSION_CODENAME == "jammy" ]]; then
			echo 'deb http://download.opensuse.org/repositories/graphics:/darktable/xUbuntu_22.04/ /' | tee /etc/apt/sources.list.d/graphics:darktable.list
			curl -fsSL https://download.opensuse.org/repositories/graphics:darktable/xUbuntu_22.04/Release.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/graphics_darktable.gpg > /dev/null
			apt-get update
			apt-get -qq install darktable
		elif [[ $VERSION_CODENAME == "bullseye" ]]; then
			apt-get update
			apt-get -qq install -t bullseye-backports darktable
		elif [[ $VERSION_CODENAME == "buster" ]]; then
			apt-get update
			apt-get -qq install -t buster-backports darktable
		else
			echo "install-darktable: installing standard amd64 (Intel 64-bit) package"
			apt-get -qq install darktable
		fi
		;;

	arm64 | ARM64 | aarch64)
		if [[ $VERSION_CODENAME == "bullseye" ]]; then
			apt-get update
			apt-get -qq install -t bullseye-backports darktable
		elif [[ $VERSION_CODENAME == "buster" ]]; then
			apt-get update
			apt-get -qq install -t buster-backports darktable
		else
			echo "install-darktable: installing standard arm64 (ARM 64-bit) package"
			apt-get -qq install darktable
		fi
		;;

	*)
		echo "Unsupported Machine Architecture: \"$BUILD_ARCH\"" 1>&2
		exit 0
		;;
	esac
}

#
# URL https://github.com/photoprism/photoprism
#
photoprism() {
	local __version __user __pass __port
	local __dbname __dbpass __dbuser
	while [[ $# -gt 0 ]]; do
		case $1 in 
		-v | --verion)
			shift; __version="$1";;
		-u | --user)
			shift; __user="$1";;
		-pwd | --pass)
			shift; __pass="$1";;
		-p | --port)
			shift; __port="$1";;
		--dbuser )
			shift; __dbuser="$1";;
		--dbpass )
			shift; __dbpass="$1";;
		--dbname )
			shift; __dbname="$1";;
		*)
			echo "Unknow flag $1" && return;;
		esac
		shift
	done
	# default values
	__version="${__version:-""}"
	__user="${__user:-admin}"
	__pass="${__pass:-changeme}"
	__port="${__port:-2342}"

	# make temp directory as working dir
	dir=`mktemp -d` && cd $dir

	# clone photoprism source from github
	mkdir -p /opt/photoprism/bin
	git clone https://github.com/photoprism/photoprism.git .
	git checkout release
	#
	# fix on lxc - remove sudo before command if current user is root
	if [[ $(id -u) -eq 0 ]]; then 
		sed -i -e 's/sudo //g' Makefile 
	fi
	#
	# build frontend and backend
	NODE_OPTIONS=--max_old_space_size=2048 make all
	# adding cgo clags below to avoid error: https://github.com/mattn/go-sqlite3/issues/803
	CGO_CFLAGS="-g -O2 -Wno-return-local-addr" ./scripts/build.sh prod /opt/photoprism/bin/photoprism
	cp -r assets/ /opt/photoprism
	#
	# config for photoprism
	mkdir -p /var/lib/photoprism
	#
	options=" 
# https://docs.photoprism.app/getting-started/config-options/
# Initial password for the admin user
PHOTOPRISM_AUTH_MODE='password'
PHOTOPRISM_ADMIN_USER='${__user}'
PHOTOPRISM_ADMIN_PASSWORD='${__pass}'
# Host information
PHOTOPRISM_HTTP_HOST='0.0.0.0'
PHOTOPRISM_HTTP_PORT='${__port}'
PHOTOPRISM_SITE_CAPTION=''
#
# PhotoPrism storage directories
#
# writable storage PATH for sidecar, cache, and database files
PHOTOPRISM_STORAGE_PATH='/var/lib/photoprism/storage'
# storage PATH of your original media files (photos and videos)
PHOTOPRISM_ORIGINALS_PATH='/var/lib/photoprism/photos/Originals'
# base PATH from which files can be imported to originals optional
PHOTOPRISM_IMPORT_PATH='/var/lib/photoprism/photos/Import'
#PHOTOPRISM_ASSETS_PATH=''
#
# Log setting
# trace, debug, info, warning, error, fatal, panic
PHOTOPRISM_LOG_LEVEL=info
PHOTOPRISM_DEBUG=false
PHOTOPRISM_TRACE=false
# daemon-mode only
#PHOTOPRISM_LOG_FILENAME=/var/lib/photoprism/storage/photoprism.log
	"
	if [[ -n ${__dbname} && -n ${__dbuser} && -n ${__dbpass} ]]; then
		options+="
# Uncomment below if using MariaDB/MySQL instead of SQLite (the default)
PHOTOPRISM_DATABASE_DRIVER='mysql'
PHOTOPRISM_DATABASE_SERVER='localhost:3306'
PHOTOPRISM_DATABASE_NAME='${__dbname}'
PHOTOPRISM_DATABASE_USER='${__dbuser}'
PHOTOPRISM_DATABASE_PASSWORD='${__dbpass}'
	"
	fi
	# setting ENV
	env_path="/var/lib/photoprism/.env"
	echo -e "$options" > $env_path
	chmod 640 $env_path
	#
	# create a service
	service_path="/etc/systemd/system/photoprism.service"
	echo -e "
[Unit]
Description=PhotoPrism service
After=network.target

[Service]
Type=forking
User=root
# Group=root
WorkingDirectory=/opt/photoprism
EnvironmentFile=/var/lib/photoprism/.env
ExecStart=/opt/photoprism/bin/photoprism up -d
ExecStop=/opt/photoprism/bin/photoprism down

[Install]
WantedBy=multi-user.target
	" > $service_path

	# starting photoprism
	#systemctl enable --now photoprism
	systemctl enable photoprism

	# cleanup
	cd ~ && rm -r $dir
}


source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"

# photoprism variables
PUSER=admin
PPASS=changeme
PPORT=2342
#
# DB Variables
DBUSER=photoprism
DBPASS=photoprism
DBNAME=photoprism


export PROXMOX_SCRIPTS="$( dirname -- "$(pwd)"; )"

log "root check"
source ${PROXMOX_SCRIPTS}/app-scripts/root_required.sh
log "install dependences"
dependences

log "install golang"
source ${PROXMOX_SCRIPTS}/app-scripts/golang.sh 		&& golang --version 1.19.3

log "install mariadb"
source ${PROXMOX_SCRIPTS}/app-scripts/mariadb.sh 		&& mariadb --dbname $DBNAME --dbuser $DBUSER --dbpass $DBPASS

log "install nodejs"
source ${PROXMOX_SCRIPTS}/app-scripts/nodejs.sh 		&& nodejs --version 18.x

log "install tensorflow"
source ${PROXMOX_SCRIPTS}/app-scripts/tensorflow.sh 	&& tensorflow

log "install photoprism"
photoprism --user $PUSER --pass $PPASS --port $PPORT --dbuser $DBNAME --dbpass $DBPASS --dbname $DBNAME
