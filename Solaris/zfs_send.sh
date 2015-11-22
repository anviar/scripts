#!/usr/bin/bash

#=== Options ==============
zfs_pool=zshare
zfs_dataset=dataset
lockfile="/var/run/zfs_operation.lock"
zsnapname=auto_$(date +%y%m%d%H%M)
mail_recipients="admin@example.com"
RHOST=192.168.0.1
RUSER=snapuser
#==========================

function check_result {
        last_comm_res=$?
        if [[ "${last_comm_res}" -ne 0 ]]
        then
                echo "Script: an error occurred"
                cat /var/log/tones_backup.log|mailx -s "${HOSTNAME}:Pool backup error" ${mail_recipients}
                exit ${last_comm_res}
        fi

}

if [ -f ${lockfile} ]
then
        echo "Previous runjob does not complitted successfully"
        exit 1
fi

touch ${lockfile}

if [[ ! -z $(ps -ef|grep zfs|grep send|grep ${zfs_pool}) ]]
then
        echo "Sending data from pool ${zfs_pool} detected! Try again later!"
        exit 1
fi

rlast_snapshot=$(ssh ${RUSER}@${RHOST} "/usr/sbin/zfs list -o name -r ${zfs_pool}/${zfs_dataset}|tail -1"|awk -F@ '{print $2}')
zfs list -o name ${zfs_pool}/${zfs_dataset}@${rlast_snapshot} ; check_result

zfs snapshot ${zfs_pool}/${zfs_dataset}@${zsnapname} ; check_result

zfs send -i ${zfs_pool}/${zfs_dataset}@${rlast_snapshot} ${zfs_pool}/${zfs_dataset}@${zsnapname} | ssh ${RUSER}@${RHOST} "/usr/sbin/zfs recv -F ${zfs_pool}/${zfs_dataset}"
check_result

rm ${lockfile}
