#!/bin/bash

# install mariadb
mariadb() {
	local version dbname dbuser dbpass skip_add_db
	while [[ $# -gt 0 ]]; do
		case $1 in 
		-v | --verion)
			shift; version="$1";;
		-d | --dbname)
			shift; dbname="$1";;
		-u | --dbuser)
			shift; dbpuser="$1";;
		-p | --dbpass)
			shift; dbpass="$1";;
		-s | --skip-add-db)
			shift; skip_add_db="$1";;
		*)
			echo "Unknow flag $1" && return;;
		esac
		shift
	done
	# default values
	version="${version:-""}"
	dbname="${dbname:-mydb}"
	dbuser="${dbuser:-myuser}"
	dbpass="${dbpass:-mypass}"
	skip_add_db="${skip_add_db:-no}"

	if [[ -z $version ]]; then
		apt install -y mariadb-server
	else
		apt install -y mariadb-server-$version
	fi

	# config
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
	
	if [[ "${skip_add_db}" == "yes" ]]; then return; fi
	
	# create user and database
	mysql -u root -e "CREATE DATABASE ${dbname};"
	mysql -u root -e "CREATE USER ${dbuser}@localhost IDENTIFIED BY '${dbpass}';"
	mysql -u root -e "GRANT ALL PRIVILEGES ON ${dbname}.* TO ${dbuser}@localhost;"
	mysql -u root -e "FLUSH PRIVILEGES;"
	mysql -u root -e "SHOW GRANTS FOR ${dbuser}@localhost;"

	# recheck
	mysql -u root -e 'SHOW DATABASES;'
	mysql -u root -e "SELECT USER FROM mysql.user;"
}
