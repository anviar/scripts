#!/usr/local/bin/bash

hosts="10.0.0.13 10.0.0.15"
telnet_login="admin"
telnet_password="password"
ftp_host=10.0.0.24
ftp_user="ftpuser"
ftp_password="ftppass"

config_upload() {
	/usr/local/bin/expect	-c "
		spawn /usr/bin/telnet -l $telnet_login $host
		expect \"Password:*\"
		send \"$telnet_password\r\"
		proc send_config {} {
			set timeout 20
			send \"configUpload -p ftp $ftp_host,$ftp_user,config.txt,$ftp_password\r\"
			expect \"*?admin>\"
			send \"logout\r\"
		}
		proc test_break {} {
	                expect {
       				\"Use Control-C to exit or press 'Enter' key to proceed.\"
                                	{
                                        	send \003
	                                        expect \"*?admin>\"
        	                                sleep 1
		                        }
	                        \"*?admin>\"
        	                        {
                	                        sleep 1 
                        	        }
                        	timeout
                                	{
                                        	exit
                                	}
			}

		}
		test_break
		send \"setcontext $fid\r\"
		test_break
		send_config
		expect eof
	">/dev/null

}

switch_show() {
	/usr/local/bin/expect	-c "
		spawn /usr/bin/telnet -l $telnet_login $host
		expect \"Password:*\"
		send \"$telnet_password\r\"
		proc switch_show {} {
			send \"switchShow\r\"
			expect \"*?admin>\"
			send \"logout\r\"
		}
                proc test_break {} {
                        expect {
                                \"Use Control-C to exit or press 'Enter' key to proceed.\"
                                        {
                                                send \003
                                                expect \"*?admin>\"
                                                sleep 1
                                        }
                                \"*?admin>\"
                                        {
                                                sleep 1
                                        }
                                timeout
                                        {
                                                exit
                                        }
                        }

                }
		test_break
		send \"setcontext $fid\r\"
		test_break
		switch_show
		
		expect eof
	" >${workdir}/switchShow_${host}_${fid}.txt
}

lport_collect() {
	ports=$(cat ${workdir}/switchShow_$host.txt|grep L-Port|awk {'print $2'})
	portShow=$(
		for lport in $ports
		do
			echo "sent \"portShow $lport\r\""
			echo "expect \"*?admin>\"" 
		done
	)

	lport_wwns=( $(/usr/local/bin/expect   -c "
		spawn /usr/bin/telnet -l $telnet_login $host
		expect \"Password:*\"
		send \"$telnet_password\r\"
		proc port_show {} {
			$portShow
			send \"logout\r\"
		}
		expect {
			\"Use Control-C to exit or press 'Enter' key to proceed.\"
				{
					send \003
					expect \"*?admin>\"
					port_show
		
				}
			\"*?admin>\"
				{
					port_show
				}
			timeout
				{
					exit
				}
			
		}
		expect eof
	"|grep -A 1 "portWwn of device(s) connected:"|egrep -o "([a-z0-9]{2}:){7}[a-z0-9]{2}" ) )

}

summarize() {
	echo>${workdir}/summ_${host}_${fid}.txt
	cat ${workdir}/switchShow_${host}_${fid}.txt| while read line
	do
		if [[ ! -z "$(echo -e "$line"|egrep  "([a-z0-9]{2}:){7}[a-z0-9]{2}"|grep -v switchWwn)" ]]
		then
			port_wwn=$(echo "$line"|egrep -o "([a-z0-9]{2}:){7}[a-z0-9]{2}")
			#port_wwn=$(echo "$line"|awk {'print $10'}|cut -c1-23)
			port_alias=$(grep -a "$port_wwn" ${workdir}/config_${host}_${fid}.txt|sed s/alias.//|awk -F: {'print $1'}|sed 's/\x0D$//'|tr '\n' ' ')
			line="$(echo "$line"|tr -d '\15\32') $port_alias"
			echo -n "."
		fi
		echo "$line">>${workdir}/summ_${host}_${fid}.txt
	done
}

#=============================================================================================================================
prefix=/usr/local/www/brocade
workdir=${prefix}/$(date +%Y.%m.%d)
mkdir -p ${workdir}
cd ${workdir}
if [ $? -ne 0 ]; then
	exit 1
fi


for host in $hosts
do
	fid=128
	echo -n "Processing $host.."
        config_upload
        mv ~/config.txt ${workdir}/config_${host}_${fid}.txt
        switch_show
        summarize

	case $host in
		10.0.66.130 ) fid=3 ;;
		10.0.66.150 ) fid=3 ;;
		10.0.66.140 ) fid=4 ;;
		10.0.66.160 ) fid=4 ;;
	esac
	config_upload
	mv ~/config.txt ${workdir}/config_${host}_${fid}.txt
	switch_show
	summarize
	echo "all done"
done

#workdir_old=$(find ${prefix} -type d -d 1 -ctime +1 -name "20[0-9][0-9]\.[01][0-9]\.[0-3][0-9]"|tail -1)
#if [[ -z "$(diff ${workdir} ${workdir_old}|egrep -v "diff|2c2|onfiguration|---")" ]]; then
#        rm -f ${workdir}/summ_*.txt ${workdir}/config_*.txt ${workdir}/switchShow_*.txt
#	rmdir ${workdir}
#fi

