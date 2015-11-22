#!/bin/bash

PREFIX=/mnt

if [[ $1 == "-u" ]]
then
	echo "Unmounting shares:"
	for mountpoint in $(mount|awk '{if ($5 == "cifs") print $3}')
	do
		echo -ne "${mountpoint}..."
		if [[ -z $(/sbin/fuser ${mountpoint} 2>&1) ]]
		then
			sudo umount ${mountpoint}
			echo -e "\e[1;32m✓\e[0m"
		else
			echo -e "\e[1;31m✗\e[0m busy"
		fi
	done
	exit 0
fi

if [[ -z $3 ]]
then
	echo -e "\e[0;31mError: require more arguments!\e[0m\nUsage:\n\t\t$0 host_ip_or_name user_name share_name\n\tOR for detach all shares\n\t\t$0 -u"
	exit 1
fi

host=$1
user=$2
share=$3

if [[ ! -d ${PREFIX}/${host}/${share} ]]
then
	sudo mkdir -p ${PREFIX}/${host}/${share}
	echo -e "\e[0;33mInfo\e[0m: created new empty mounpoint ${PREFIX}/${host}/${share}"
fi

if [[ ! -z $(mount|awk '{if ($5 == "cifs") print $3}'|grep ${PREFIX}/${host}/${share}) ]]
then
	echo -e "\e[0;33mWarning: \"${share}\" already mounted!\e[0m"
else
	sudo mount -t cifs -o username=${user} //${host}/${share} ${PREFIX}/${host}/${share}
fi

[[ $? -eq 0 ]] && nautilus --browser ${PREFIX}/${host}/${share}
