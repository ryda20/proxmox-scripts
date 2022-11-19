#!/bin/bash

apt install -y curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"

tomcat_remove() {
	log --header "tomcat remover"
	log "stop tomcat service"
	systemctl stop tomcat
	rm /etc/systemd/system/tomcat.service

	log "remove tomcat user and group"
	userdel tomcat
	groupdel tomcat

	log "remove /opt/tomat folder"
	rm -rf /opt/tomcat
}

TOMCAT_HOME=/opt/tomcat
tomcat_installation() {
	local ver=9.0.68
	# local TOMCAT_HOME=/opt/tomcat
	log --step "INSTALL TOMCAT SERVER ${ver}"

	# todo: java version detection
	
	local working_dir=/tmp/tomcat-installation
	mkdir -p ${working_dir}
	cd ${working_dir}

	
	log --step "installing openjdk-11"
	apt install -y openjdk-11-jdk

	log --step "creating tomcat user, /opt/tomcat directory"
	groupadd tomcat
	useradd -g tomcat -d /opt/tomcat -s /usr/sbin/nologin tomcat
	mkdir -p /opt/tomcat

	# not only install tomcat 9, tomcat 10 got error
	# https://stackoverflow.com/questions/66711660/tomcat-10-x-throws-java-lang-noclassdeffounderror-on-javax-servlet
	log --step "downloading tomcat..."
	wget -O apache-tomcat-${ver}.tar.gz https://dlcdn.apache.org/tomcat/tomcat-9/v${ver}/bin/apache-tomcat-${ver}.tar.gz
	#
	log --step "installing tomcat..."
	tar -xvzf apache-tomcat-${ver}.tar.gz
	rm -rf ${TOMCAT_HOME}/*
	mv apache-tomcat-${ver}/* ${TOMCAT_HOME}/
	chown -R tomcat:tomcat ${TOMCAT_HOME}/
	#
	echo -e " 
[Unit]
Description=Apache Tomcat 9.x Web Application Container
Wants=network.target
After=network.target
[Service]
Type=forking
Environment=JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64/
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1G -Djava.net.preferIPv4Stack=true'
Environment='JAVA_OPTS=-Djava.awt.headless=true'
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
SuccessExitStatus=143
User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always
[Install]
WantedBy=multi-user.target
	" > /etc/systemd/system/tomcat.service

	systemctl daemon-reload
	systemctl start tomcat
	systemctl enable tomcat

	cd ~
	log --step "cleanup..."
	rm -r ${working_dir}
	sleep 2
	# systemctl status tomcat
	log --step "Tomcat listen: $( ss -antpl | grep 8080 )"
}
# libwebp6 -> debian
# libwebp-dev -> ubuntu
# libjpeg62-turbo-dev -> debian
# libjpeg62-dev -> ubuntu
# libjpeg-dev -> debian
#
guacamole_server_remove() {
	log_header "guacamole server remover"
	/etc/init.d/guacd stop 
	rm /etc/init.d/guacd
	# apt remove -y libcairo2 libwebp6
}
guacamole_server_installation() {
	local ver=1.4.0
	log_header "GUACD INSTALLATION $ver"

	local working_dir=/tmp/guacamole-cd-installation
	mkdir -p ${working_dir}
	cd ${working_dir}

	
	#https://guacamole.apache.org/doc/gug/installing-guacamole.html
	log "installing requirement package to run guacd"
	# apt update && 
	apt install -y libcairo2 libwebp6

	log "installing packages for compiling process"
	DEPS="make libcairo2-dev libjpeg62-turbo-dev libpng-dev libtool-bin uuid-dev"
	OPT_DEPS="libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev" 
	# apt update && 
	apt install -y ${DEPS} ${OPT_DEPS}
	

	log "downloading guacamole-server..."
	wget -O guacamole-server-${ver}.tar.gz https://apache.org/dyn/closer.lua/guacamole/${ver}/source/guacamole-server-${ver}.tar.gz?action=download

	log "extracting..."
	tar -xzf guacamole-server-${ver}.tar.gz
	cd guacamole-server-${ver}
	log "configure..."
	./configure --with-init-dir=/etc/init.d --disable-dependency-tracking
	log "make..."
	make
	make install
	ldconfig

	sleep 2
	log "write config file for guacd"
	#https://guacamole.apache.org/doc/gug/configuring-guacamole.html#id12
	mkdir -p /etc/guacamole
	echo '
#
# guacd configuration file
#

[daemon]
pid_file = /var/run/guacd.pid
log_level = info

[server]
# note: dont use locahost -> will not working
# nomarly without this config (using by default) will be point to ::1
bind_host = 127.0.0.1
bind_port = 4822

#
# The following parameters are valid only if
# guacd was built with SSL support.
#
[ssl]
# server_certificate = path to cer file
# server_key = path to key file
	' > /etc/guacamole/guacd.conf


	# make guacd script run at startup
	update-rc.d guacd defaults
	systemctl start guacd
	systemctl enable guacd

	cd ~
	log "cleanup..."
	# apt remove -y ${DEPS} ${OPT_DEPS}
	# apt autoremove -y
	rm -r ${working_dir}

	# check guacd running with command /etc/init.d/guacd status
	log "install completed!. You can check status with command: /etc/init.d/guacd status"
}

guacamole_client_remove() {
	echo ""
	# rm -r $GUACAMOLE_HOME
	# systemctl stop postgresql
	# sleep 2
	# apt remove -y postgresql
	# rm -rf /var/lib/postgresql/
	# rm -rf /var/log/postgresql/
	# rm -rf /etc/postgresql/
	
}

guacamole_client_installation() {
	local ver=1.4.0
	log_header "GUACAMOLE CLIENT INSTALLATION ${ver}"

	local working_dir=/tmp/guacamole-client-installation
	
	mkdir -p ${working_dir}
	cd ${working_dir}

	#
	log "downloading..."
	# install by download and build -> take many time
	# apt install -y maven
	# wget -O guacamole-client-${ver}.tar.gz https://apache.org/dyn/closer.lua/guacamole/${ver}/source/guacamole-client-${ver}.tar.gz?action=download
	# tar -xzf guacamole-client-${ver}.tar.gz
	# cd guacamole-client-${ver}/
	# export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64/
	# mvn package
	# cp target/guacamole-1.4.0.war /opt/tomcat/webapps/guacamole.war
	#
	# so, download rebuild package and extract it for easy
	# clear tomcat files first
	rm -r /opt/tomcat/webapps/*
	wget -O /opt/tomcat/webapps/ROOT.war https://apache.org/dyn/closer.lua/guacamole/${ver}/binary/guacamole-${ver}.war?action=download
	chown -R tomcat:tomcat /opt/tomcat/

	log "restarting tomcat..."
	systemctl restart tomcat
	
	log "cleanup..."
	cd ~
	rm -rf ${working_dir}
	log "installation is finished. you can go to: http://[IP]:8080/guacamole"
	

	log_header "CONFIG GUACAMOLE"

	local DATABASE_NAME=${1:-guacamole_db}
	local DATABASE_USER=${1:-guacamole_user}
	local DATABASE_PASS=${1:-some_password}
	# local ver=1.4.0
	local working_dir=/tmp/guacamole-config
	mkdir -p ${working_dir}
	cd ${working_dir}


	
	
	log "set env and create necessery directories"
	export GUACAMOLE_HOME=/etc/guacamole
	echo 'export GUACAMOLE_HOME=/etc/guacamole' >> ~/.bashrc
	mkdir -p $GUACAMOLE_HOME
	mkdir -p $GUACAMOLE_HOME/extensions
	mkdir -p $GUACAMOLE_HOME/lib

	log "install postgresql database..."
	# apt update && 
	apt install -y postgresql

	# # need ?
	# PATH=$PATH:/usr/lib/postgresql/13/bin/
	# export $PATH
	# echo 'PATH=$PATH:/usr/lib/postgresql/13/bin/' >> ~/.bashrc
	# mkdir -p /var/lib/postgres/data
	# chown postgres:postgres /var/lib/postgres/data
	# runuser -l postgres -c "/usr/lib/postgresql/13/bin/initdb -D /var/lib/postgres/data"



	log "downloading guacamole-auth-jdbc"
	wget -O ${working_dir}/guacamole-auth-jdbc-${ver}.tar.gz https://apache.org/dyn/closer.lua/guacamole/${ver}/binary/guacamole-auth-jdbc-${ver}.tar.gz?action=download
	ls -lash ${working_dir}
	tar -xzf ${working_dir}/guacamole-auth-jdbc-${ver}.tar.gz
	cp guacamole-auth-jdbc-${ver}/postgresql/guacamole-auth-jdbc-postgresql-${ver}.jar $GUACAMOLE_HOME/extensions/

	log "create database user and grant permission..."
	#su - postgres
	# dropdb before we create new one to clear all old data if have
	runuser -l postgres -c "dropdb ${DATABASE_NAME}"
	runuser -l postgres -c "createdb ${DATABASE_NAME}"
	cat guacamole-auth-jdbc-${ver}/postgresql/schema/*.sql | runuser -l postgres -c "psql -d ${DATABASE_NAME} -f -"
	# create database user and grand it to database name
	# delete db user first if have
	runuser -l postgres -c "dropuser ${DATABASE_USER}"
	runuser -l postgres -c "psql -d ${DATABASE_NAME} -c \"CREATE USER ${DATABASE_USER} WITH PASSWORD '${DATABASE_PASS}';\""
	runuser -l postgres -c "psql -d ${DATABASE_NAME} -c \"GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO ${DATABASE_USER};\""
	runuser -l postgres -c "psql -d ${DATABASE_NAME} -c \"GRANT SELECT,USAGE ON ALL SEQUENCES IN SCHEMA public TO ${DATABASE_USER};\""
	# logout # exit postgres user
	# logout if used sudo su -
	# exit if used sudo -s
	

	log "download JDBC driver for postgresql..."
	# https://jdbc.postgresql.org/download/postgresql-42.5.0.jar
	wget -O $GUACAMOLE_HOME/lib/postgresql-42.5.0.jar https://jdbc.postgresql.org/download/postgresql-42.5.0.jar


	echo "
# properties: https://guacamole.apache.org/doc/gug/configuring-guacamole.html
allowed-languages: en
guacd-hostname: 127.0.0.1
guacd-port:     4822
###### Properties used by BasicFileAuthenticationProvider
# basic-user-mapping: /etc/guacamole/user-mapping.xml
# skip-if-unavailable: mysql, ldap

### http://guacamole.apache.org/doc/gug/jdbc-auth.html
### PostgreSQL properties
postgresql-hostname: 127.0.0.1
postgresql-database: ${DATABASE_NAME}
postgresql-username: ${DATABASE_USER}
postgresql-password: ${DATABASE_PASS}
## options:
postgresql-port: 5432
postgresql-user-password-min-length: 8
postgresql-user-password-require-multiple-case: true
postgresql-user-password-require-symbol: true
postgresql-user-password-require-digit: true
postgresql-user-password-prohibit-username: true
postgresql-user-password-min-age: 7
postgresql-user-password-max-age: 90
postgresql-user-password-history-size: 6
postgresql-default-max-connections: 1
postgresql-default-max-group-connections: 1
postgresql-default-max-connections-per-user: 0
postgresql-default-max-group-connections-per-user: 0
postgresql-absolute-max-connections: 0
postgresql-user-required: true
postgresql-auto-create-accounts: true
	" > $GUACAMOLE_HOME/guacamole.properties

	echo '
<user-mapping>

	<!-- Per-user authentication and config information -->
	<authorize username="USERNAME" password="PASSWORD">
		<protocol>vnc</protocol>
		<param name="hostname">localhost</param>
		<param name="port">5900</param>
		<param name="password">VNCPASS</param>
	</authorize>

	<!-- Another user, but using md5 to hash the password
		(example below uses the md5 hash of "PASSWORD") -->
	<authorize
			username="USERNAME2"
			password="319f4d26e3c536b5dd871bb2c52e3178"
			encoding="md5">

		<!-- First authorized connection -->
		<connection name="localhost">
			<protocol>vnc</protocol>
			<param name="hostname">localhost</param>
			<param name="port">5901</param>
			<param name="password">VNCPASS</param>
		</connection>

		<!-- Second authorized connection -->
		<connection name="otherhost">
			<protocol>vnc</protocol>
			<param name="hostname">otherhost</param>
			<param name="port">5900</param>
			<param name="password">VNCPASS</param>
		</connection>

	</authorize>

</user-mapping>
	' > $GUACAMOLE_HOME/user-mapping.xml

	echo '
<configuration>

	<!-- Appender for debugging -->
	<appender name="GUAC-DEBUG" class="ch.qos.logback.core.ConsoleAppender">
		<encoder>
			<pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
		</encoder>
	</appender>

	<!-- Log at DEBUG level -->
	<root level="debug">
		<appender-ref ref="GUAC-DEBUG"/>
	</root>

</configuration>
	' > $GUACAMOLE_HOME/logback.xml

	cd ~
	log "cleanup..."
	rm -r ${working_dir}
	log "config guacamole finished"

	log "restart guacd, tomcat"
	systemctl restart guacd
	systemctl restart tomcat
	
}

main() {
	log_title "guacamole installation script" "the script tested on debian 11 in proxmox lxc"
	apt update
	# change timezone
	local YOUR_TIME_ZONE="Asia/Ho_Chi_Minh"
	ln -sf /usr/share/zoneinfo/${YOUR_TIME_ZONE} /etc/localtime
	# need to reboot to apply timezone
	# or using dpkg-reconfigure tzdata to change timezone

	tomcat_remove
	tomcat_installation
	guacamole_server_remove
	guacamole_server_installation
	guacamole_client_remove
	guacamole_client_installation 
	# rm -rf /var/lib/apt/lists/*
	# apt autoremove -y
	log_end
}

## starting ##
main "$@"
