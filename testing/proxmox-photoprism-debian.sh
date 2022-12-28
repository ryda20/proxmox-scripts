#!/bin/bash

#
# URL https://github.com/photoprism/photoprism
#

# install depending
apt install -y git curl gcc g++ gnupg make zip unzip exiftool ffmpeg

# install nodejs
curl -sL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# install golang
wget https://golang.org/dl/go1.19.3.linux-amd64.tar.gz
tar -xzf go1.19.3.linux-amd64.tar.gz -C /usr/local
ln -s /usr/local/go/bin/go /usr/local/bin/go
go install github.com/tianon/gosu@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/psampaz/go-mod-outdated@latest
go install github.com/dsoprea/go-exif/v3/command/exif-read-tool@latest
go install github.com/mikefarah/yq/v4@latest
go install github.com/kyoh86/richgo@latest
cp /root/go/bin/* /usr/local/go/bin/
cp /usr/local/go/bin/richgo /usr/local/bin/richgo
cp /usr/local/go/bin/gosu /usr/local/sbin/gosu
chown root:root /usr/local/sbin/gosu
chmod 755 /usr/local/sbin/gosu

# install tensorlow
AVX=$(grep -o -m1 'avx[^ ]*' /proc/cpuinfo)
if [[ "$AVX" =~ avx2 ]]; then
  wget https://dl.photoprism.org/tensorflow/linux/libtensorflow-linux-avx2-1.15.2.tar.gz
  tar -C /usr/local -xzf libtensorflow-linux-avx2-1.15.2.tar.gz
elif [[ "$AVX" =~ avx ]]; then
  wget https://dl.photoprism.org/tensorflow/linux/libtensorflow-linux-avx-1.15.2.tar.gz
  tar -C /usr/local -xzf libtensorflow-linux-avx-1.15.2.tar.gz
else
  wget https://dl.photoprism.org/tensorflow/linux/libtensorflow-linux-cpu-1.15.2.tar.gz
  tar -C /usr/local -xzf libtensorflow-linux-cpu-1.15.2.tar.gz
fi
ldconfig

# clone photoprism source from github
mkdir -p /opt/photoprism/bin
mkdir -p /var/lib/photoprism/storage
git clone https://github.com/photoprism/photoprism.git
cd photoprism
git checkout release
#
# build
NODE_OPTIONS=--max_old_space_size=2048 make all
./scripts/build.sh prod /opt/photoprism/bin/photoprism
cp -r assets/ /opt/photoprism
#
# setting ENV
env_path="/var/lib/photoprism/.env"
echo " 
PHOTOPRISM_AUTH_MODE='password'
PHOTOPRISM_ADMIN_PASSWORD='changeme'
PHOTOPRISM_HTTP_HOST='0.0.0.0'
PHOTOPRISM_HTTP_PORT='2342'
PHOTOPRISM_SITE_CAPTION='https://photos.rydafa.com'
PHOTOPRISM_STORAGE_PATH='/var/lib/photoprism/storage'
PHOTOPRISM_ORIGINALS_PATH='/var/lib/photoprism/photos/Originals'
PHOTOPRISM_IMPORT_PATH='/var/lib/photoprism/photos/Import'
" >$env_path
#
# create a service
service_path="/etc/systemd/system/photoprism.service"
echo "[Unit]
Description=PhotoPrism service
After=network.target
[Service]
Type=forking
User=root
WorkingDirectory=/opt/photoprism
EnvironmentFile=/var/lib/photoprism/.env
ExecStart=/opt/photoprism/bin/photoprism up -d
ExecStop=/opt/photoprism/bin/photoprism down
[Install]
WantedBy=multi-user.target" >$service_path

# cleaning up
apt autoremove
apt autoclean
rm -rf /var/{cache,log}/* \
  /photoprism \
  /go1.19.3.linux-amd64.tar.gz \
  /libtensorflow-linux-avx2-1.15.2.tar.gz \
  /libtensorflow-linux-avx-1.15.2.tar.gz \
  /libtensorflow-linux-cpu-1.15.2.tar.gz

# starting photoprism
systemctl enable --now photoprism
