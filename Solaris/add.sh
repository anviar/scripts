#!/bin/bash

# Basic configuration
add_tool=/export/home/jumpstart/install/Solaris_10/Tools/add_install_client
share_prefix="10.0.64.226:/export/home/jumpstart"
config_prefix=/export/home/jumpstart/config

if [[ -z "$1" ]] ; then
	echo -e "Usage: add.sh hostname [arch]"
	exit 2
fi

if [[ ! -z "$2" ]] ; then
	arch=$2
else
	arch=sun4v
fi

if [[ ! -d "${config_prefix}/$1" ]] ; then
	echo "Warning: Cannot find configuration in ${config_prefix}/$1"
	echo "Generating from sample..."
	cp -r ${config_prefix}/sample ${config_prefix}/$1
	mv ${config_prefix}/$1/sample ${config_prefix}/$1/$1
	cat ${config_prefix}/sample/rules|sed s/sample/$1/g>${config_prefix}/$1/rules
fi

cd ${config_prefix}/$1
./check

if [[ "$?" != "0" ]]; then
	echo "Error: Check your configuration and try again"
	exit 1
fi

if [[ -z "$(grep $1 /etc/ethers)" ]] ; then
	ping $1
	if [[ "$?" != "0" ]]; then
		echo "Error: Add $1 to /etc/hosts, check network connection or edit /etc/ethers manualy!"
		exit 1
	else
		echo -e "$(arp $1|awk {'print $4'})\t$1">>/etc/ethers	
	fi
fi

#$add_tool -c $share_prefix/config/$1 -p  $share_prefix/config/$1 -s  $share_prefix/install $1 $arch
echo "All done! Try to boot now."
