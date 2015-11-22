#!/usr/bin/bash

#=== Options ==============
zfs_pool=zshare
zfs_dataset=dataset 
#=========================
nsnap=$(zfs list -o name -r ${zfs_pool}/${zfs_dataset}|egrep "@auto_1[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"|wc -l)
if [[ ${nsnap} -gt 3 ]]
then
      let "nsnap_destroy = $nsnap - 2"
      snap_destroy_list=$(zfs list -o name -r ${zfs_pool}/${zfs_dataset}|egrep "@auto_[0-9]10"|head -n ${nsnap_destroy})
      for dsnap in ${snap_destroy_list}
      do
              zfs destroy ${dsnap}
      done
fi