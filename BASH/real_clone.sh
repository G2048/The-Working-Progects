#!/bin/bash
#Running: sudo real_clone.sh support@10.10.13.249

password='support'
password_local='1'
prefix=$(date '+%F')
default_path="/var/lib/staffcop/staffcop_backup/staffcop-db.dump${prefix}"

if [[ "$1" = "" ]]; then

	printf "Usage: $0 <SSH-USER>@<REMOTE-HOST>\n"
	exit
fi

credentials="$1"

if [[ ! -e "${HOME}/.ssh/id_rsa" ]]; then
	ssh-keygen -t rsa &&  echo -e $password | ssh-copy-id $credentials
fi

#echo -e $password | ssh support@10.10.13.249 " sudo -S staffcop info"

	
sudo -u postgres pg_dump --verbose --compress=7 --clean --create --blobs --format=c --file=$default_path --dbname=staffcop

#sudo scp $default_path ${credentials}:${default_path}
echo -e $password | sudo -S rsync -varz -e "ssh" $default_path ${credentials}:${default_path} 
#scp $default_path ${credentials}:${default_path}
echo -e $password | ssh ${credentials} "sudo -S staffcop stop; sudo chown postgres:postgres ${default_path};sudo -u postgres pg_restore  --clean --create --format=c --verbose ${default_path} -d postgres; sudo staffcop start"

