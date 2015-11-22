#!/bin/bash

export LANG=POSIX

#Настройки

PREFIX=/var/www/BACKUPS/
htdocs_prefix=${PREFIX}/htdocs/
Dropbox_prefix=/var/www/BACKUPS/Dropbox_nodes/
Dropbox_accs=( "01" "02" "03" )

# Лимит 2G
limit=2097152

Dbox_id=0
for i in ${htdocs_prefix}/$(ls -1 -rt ${htdocs_prefix}|tail -n 1)/*.tar.gz
do
    ln -s "$i" "${Dropbox_prefix}/${Dropbox_accs[$Dbox_id]}/$(basename $i)"
    if [[ "$(du -sL ${Dropbox_prefix}/${Dropbox_accs[$Dbox_id]}/|awk {'print $1'})" -gt "$limit" ]]
    then
	echo "Переход на новую шару"
	rm -f ${Dropbox_prefix}/${Dropbox_accs[$Dbox_id]}/$(basename $i)
	let "Dbox_id = $Dbox_id + 1"
	ln -s "$i" "${Dropbox_prefix}/${Dropbox_accs[$Dbox_id]}/$(basename $i)"
	
	if [[ "$(du -sL ${Dropbox_prefix}/${Dropbox_accs[$Dbox_id]}|awk {'print $1'})" -gt "$limit" ]]
	then
	    rm -f ${Dropbox_prefix}/${Dropbox_accs[$Dbox_id]}/$(basename $i)
	    echo "$(basename $i) слишком велик! Пропускаю."
	fi
    fi
done
