#!/bin/bash -e
#This script was created for the archive data base restore 
#Example: script_for_convert.sh /path/to/dump/staffcop-db.dump

default_path="/var/lib/staffcop/staffcop_backup/staffcop-db.dump"


function CREATE_TABLESPACE() {

	read -p "Выбрать дефолтный путь до холодного хранилища? (Y/N) " -r _choose

	case "$_choose" in 

		[Yy])
		_path="/var/lib/staffcop/upload/filedata/cold_databases"
		;;

		[Nn])
		read -p "Введите полный путь до холодного хранилища (точки монтирования): " -r _path 
		;;
	esac
	
	#read -p "Введите Имя TABLESPASE: " -r tspace
	if [[ ! -d $_path ]] ; then
		sudo mkdir "$_path" 2> /dev/null
		sudo chown -R postgres: $_path
		sudo chmod 700 $_path
	fi

	location="${_path}/${storage}"
	sudo mkdir "$location" 2> /dev/null
	sudo chown -R postgres: $location 
	sudo chmod 700 $location
	sudo -u postgres psql -c "CREATE TABLESPACE ${storage} LOCATION '${location}'"
}

function STOP() {

	staffcop stop
	sudo -u postgres psql -c "SELECT pid, datname, usename, pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename='staffcop';"
}

function START() {

	sudo systemctl stop postgresql
	sudo systemctl start postgresql
	staffcop start
}

function CLICKHOUSE() {

	if type clickhouse; then
		read -p "Выходите создать архивную БД для clickhouse? (Yes/No) " -r _click

		case "$_click" in

		[Yy])
		OVERRIDE_DBNAME=${storage} staffcop clickhouse reinit
		OVERRIDE_DBNAME=${storage} staffcop clickhouse pump
		;;

		*) return 0 ;;
		esac
	fi
}

function CONFIG() {

	local backconf="$HOME/backup_config_$(date '+%T')"
	sudo cp /etc/staffcop/config $backconf 
	printf '\nБэкап конфига %s создан! \n\n' "$backconf"

	#storage="archive2"
	HEAD="DATABASES = {"
	TEMPLATE="'default': {
			'ENGINE': 'django.db.backends.postgresql_psycopg2',
			'NAME': 'staffcop',
			'USER': 'staffcop',
			'PASSWORD': 'xxx',
			'HOST': '',
			'PORT': '',
		}"

	KEY=$(grep -iPo "(?<='PASSWORD':\s ').*[^',]" /etc/staffcop/config | tail -n 1)
	TEMPLATE=$(printf "${TEMPLATE}\n" | sed -e "s:xxx:${KEY}:")
	new_config=$(printf "${TEMPLATE}\n" | sed -e "s:default:$1:; 2,3s:staffcop:$1:")
	CORE=$(grep -Pizo "((?=').*\s*}?,?)" $backconf | tr -d '\0')
	ETL=$(grep -Pio "ETL=True" $backconf | tr -d '\0')

	#--FOR-DEBAGGING--#
	#printf "" > new_config.txt
	#printf "$HEAD\n" >> new_config.txt
	#printf "${TEMPLATE[@]},\n" >> new_config.txt
	#printf "$new_config\n" >> new_config.txt


	printf "" > /etc/staffcop/config
	printf "$HEAD\n" >> /etc/staffcop/config
	printf "$CORE,\n" >> /etc/staffcop/config
	printf "$new_config\n}\n" >> /etc/staffcop/config
	printf "$ETL\n" >> /etc/staffcop/config
	printf "Файл конфигурации /etc/staffcop/config - изменен! \n\n"
}

function ALTER_CURRENT_DB() {

	 read -p "Вы хотите перенести БД в существующее хранилище? (Y/N) " -r _currentmv
	 case "$_currentmv" in

	 [Yy]) 
		 echo "SELECT spcname FROM pg_tablespace WHERE spcname NOT IN ('pg_default','pg_global')" | staffcop sql	 
		 read -p "Введите имя холодного хранилища: " -r _tbspace

		 echo "SELECT datname FROM pg_database WHERE datname NOT IN ('postgres','template1','template0')" | staffcop sql
		 read -p "Введите переносимую Базу Данных: " -r _mvbd

		 sudo -u postgres psql -c  "ALTER DATABASE $_mvbd SET TABLESPACE $_tbspace"
		 CONFIG $_mvbd
		 START
		 CLICKHOUSE
		 exit 
	 ;;
	 esac
 }

function main() {

	storage="archive_db_$(date '+%Y_%m_%d')"
	#sudo -u postgres psql -c "ALTER ROLE staffcop WITH CREATEDB"

	read -p "Вы хотите сделать Архивную Базу Данных из текущей БД или из Дампа? (C/D): " -r _answer
	
	case "$_answer" in

	 [Cc]) 
	 STOP
	 ALTER_CURRENT_DB
	 CREATE_TABLESPACE
	 sudo -u postgres psql -c "CREATE DATABASE $storage OWNER staffcop TEMPLATE staffcop TABLESPACE $storage"
	 CONFIG $storage
	 START
	 CLICKHOUSE
	 ;; 

	 [Dd])
	 RESTORE "$1" 
	 CLICKHOUSE
	 ;;

		*) printf "\nПожалуйста введите A/a или D/d...\n\n" ; main $@ ;;
	esac
}

function RESTORE() {

	# $1 - путь до дампа
	path=${1=default_path}
		
	CONFIG $storage

	#printf "Drop database...\n"
	#sudo -u postgres dropdb $1
	printf "Create database...\n"
	sudo -u postgres createdb --owner=staffcop $storage
	printf "Restore database...\n"
	sudo -u postgres pg_restore --data-only --format=c --verbose --dbname="$storage" $path

	read -p "Вы хотите перенести Архивную Базу Данных на другое хралище? (Yes/No?)" -r _move
	
	case "$_move" in

	[Yy]) 

	CREATE_TABLESPACE
	echo "ALTER DATABASE $storage SET TABLESPACE $storage" | staffcop sql
	START
	;;

	*) START ;;
	esac
}

main $@
#CONFIG $@
