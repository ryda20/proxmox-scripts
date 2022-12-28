#!/bin/bash

# photoprism variables
USER=admin
PASS=changeme
PORT=2342
#
# DB Variables
DBUSER=photoprism
DPPASS=photoprism
DPNAME=photoprism


# install mariadb
apt install mariadb-server
mysql_secure_installation
#
# run sql command from terminal
# mysql -u user -p 'password' -e 'Your SQL Query Here' database-name
# -u : Specify mysql database user name
# -p : Prompt for password
# -e : Execute sql query
# database : Specify database name
# Ex: mysql -u vivek -p -e 'show databases;'
# Ex: mysql -u vivek -p -e 'SELECT COUNT(*) FROM quotes' cbzquotes
# create user and database
mysql -u root -e 'show databases;'
mysql -u root -e "CREATE DATABASE ${DPNAME};"
mysql -u root -e 'SHOW DATABASES;'
mysql -u root -e "CREATE USER ${DBUSER}@localhost IDENTIFIED BY '${DPPASS}';"
mysql -u root -e "SELECT USER FROM mysql.user;"
mysql -u root -e "GRANT ALL PRIVILEGES ON ${DPNAME}.* TO ${DBUSER}@localhost;"
mysql -u root -e "FLUSH PRIVILEGES;"
mysql -u root -e "SHOW GRANTS FOR ${DBUSER}@localhost;"



#
# URL https://github.com/photoprism/photoprism
#

# install depending
apt install -y git curl gcc g++ gnupg make zip unzip exiftool ffmpeg

# install nodejs
curl -sL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# install golang
rm -rf /usr/local/go
wget https://golang.org/dl/go1.19.3.linux-amd64.tar.gz
tar -xzf go1.19.3.linux-amd64.tar.gz -C /usr/local
ln -s /usr/local/go/bin/go /usr/local/bin/go
rm go1.19.3.linux-amd64.tar.gz

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
git clone https://github.com/photoprism/photoprism.git
cd photoprism
git checkout release
#
# build
NODE_OPTIONS=--max_old_space_size=2048 make all
./scripts/build.sh prod /opt/photoprism/bin/photoprism
cp -r assets/ /opt/photoprism
#
# config for photoprism
mkdir -p /var/lib/photoprism
#
# setting ENV
env_path="/var/lib/photoprism/.env"
echo " 
# https://docs.photoprism.app/getting-started/config-options/
# Initial password for the admin user
PHOTOPRISM_AUTH_MODE='password'
PHOTOPRISM_ADMIN_USER='${USER}'
PHOTOPRISM_ADMIN_PASSWORD='${PASS}'
# Host information
PHOTOPRISM_HTTP_HOST='0.0.0.0'
PHOTOPRISM_HTTP_PORT='${PORT}'
PHOTOPRISM_SITE_CAPTION='https://photos.rydafa.com'
# PhotoPrism storage directories
PHOTOPRISM_STORAGE_PATH='/var/lib/photoprism/storage'
PHOTOPRISM_ORIGINALS_PATH='/var/lib/photoprism/photos/Originals'
PHOTOPRISM_IMPORT_PATH='/var/lib/photoprism/photos/Import'
# Log setting
# trace, debug, info, warning, error, fatal, panic
PHOTOPRISM_LOG_LEVEL=info
PHOTOPRISM_DEBUG=false
PHOTOPRISM_TRACE=false
# daemon-mode only
#PHOTOPRISM_LOG_FILENAME=/var/lib/photoprism/storage/photoprism.log
# # Uncomment below if using MariaDB/MySQL instead of SQLite (the default)
PHOTOPRISM_DATABASE_DRIVER='mysql'
PHOTOPRISM_DATABASE_SERVER='localhost:3306'
PHOTOPRISM_DATABASE_NAME='${DBNAME}'
PHOTOPRISM_DATABASE_USER='${DBUSER}'
PHOTOPRISM_DATABASE_PASSWORD='${DBPASS}'
" >$env_path
chmod 640 $env_path
#
# create a service
service_path="/etc/systemd/system/photoprism.service"
echo "[Unit]
Description=PhotoPrism service
After=network.target
[Service]
Type=forking
User=root
Group=root
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
