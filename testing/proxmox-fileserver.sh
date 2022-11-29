#!/bin/bash

#### FileBrowser
# https://filebrowser.org
# https://github.com/filebrowser/filebrowser

get_latest_release() {
	curl -L "${1}/releases/latest" | # get the latest release from github page, it will auto redirect to latest tag page (-L)
	grep "<title>Release " | # get the title line with latest version
	sed -E 's/.*(v[0-9]+\.[0-9]+\.[0-9]+).*/\1/' # replace anything with the matched one - here - matching the version look like: vxx.xx.xx
}

BASE_URL=https://github.com/filebrowser/filebrowser
VERSION=$(get_latest_release ${BASE_URL})
URL_RELEASE=${BASE_URL}/releases/tag/${VERSION}
OS_NAME=$(uname -o) # Linux
[[ "${OS_NAME}" != "Linux" ]] && echo "This version only support for Linux" && return

OS_ARCH=$( [[ "$(uname -m)" == "x86_64" ]] && echo "amd64" || echo "" )

FILE_NAME=${OS_NAME}-${OS_ARCH}-filebrowser

URL_DOWNLOAD=${BASE_URL}/releases/download/${VERSION}/${FILE_NAME}.tar.gz

#https://github.com/filebrowser/filebrowser/releases/download/v2.23.0/windows-amd64-filebrowser.zip
#https://github.com/filebrowser/filebrowser/releases/download/v2.23.0/linux-amd64-filebrowser.tar.gz

mkdir /tmp/${FILE_NAME}
wget -O /tmp/${FILE_NAME}/${FILE_NAME}.tar.gz ${URL_DOWNLOAD}
cd /tmp/${FILE_NAME} && tar -xf ${FILE_NAME}.tar.gz

# create necessery dir
mkdir /app
mkdir /srv

# write config file
echo << 'EOF' > /app/filebrowser.json
{
	"port": 8081,
	"baseURL": "",
	"address": "",
	"log": "stdout",
	"database": "/app/database.db",
	"root": "/srv"
}
EOF

cp /tmp/${FILE_NAME}/filebrowser /app/

# create service to run filebrowser
cat << 'EOF' > /etc/init.d/filebrowser
#!/sbin/openrc-run
description="FileBrowser"

command="/app/filebrowser"
command_args=""
command_background="yes"
directory="/app"

pidfile="/var/run/filebrowser.pid"
output_log="/var/log/filebrowser.log"
error_log="/var/log/filebrowser.err"

depends () {
	echo "depending here"
}

start_pre() {
	echo "start pre"
}

stop() {
	pkill -9 -f filebrowser
	return 0
}

restart() {
	$0 stop
	$0 start
}
EOF

chmod a+x /etc/init.d/filebrowser
# start at boot
rc-updaet add filebrowser boot &>/dev/null
# starting
rc-service filebrowser start

IP=$(ip a s dev eth0 | sed -n '/inet / s/\// /p' | awk '{print $2}')

echo "http://${IP}:8081"
