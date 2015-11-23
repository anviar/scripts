#!/usr/local/bin/bash

hosts="10.0.0.1"
telnet_login="admin"
telnet_password="password"


for host in ${hosts}
do

	config_file=/usr/local/www/brocade/$(date +%Y.%m.%d)/config_${host}.txt	
	zones_enabled="$(cat ${config_file}|grep -a "cfg.TELE2"|awk -F: {'print $2'}|sed s/\;/\|/g)"
	aliases_enabled="$(cat ${config_file}|grep -a "zone\."|egrep "${zones_enabled}"|awk -F: {'print $2"|"'}|sed s/\;/\|/g|tr -d '\n'|sed 's/.$//')"
	aliases_disabled=$(cat ${config_file}|grep -a "alias."|egrep -av "${aliases_enabled}"|sed s/alias\.//g|awk -F: {'print $1'})
	alidelete=$(
		for alias in ${aliases_disabled}
		do
			echo "send \"aliDelete $alias\\r\""
			echo "expect \"*?admin>\""
		done
	)
	/usr/local/bin/expect -c "
                spawn /usr/bin/telnet -l $telnet_login $host
                expect \"Password:*\"
                send \"$telnet_password\r\"
                proc alias_delete {} {
                        $alidelete
                        send \"cfgSave\r\"
                        expect \"Do you want to save Defined zoning configuration only?*\"
                        send \"y\r\"
			expect \"*?admin>\"
			send \"cfgEnable TELE2\r\"
                        expect \"Do you want to enable*\"
                        send \"y\r\"
                        expect \"*?admin>\"
                        send \"logout\r\"
                }
                expect {
                        \"Use Control-C to exit or press 'Enter' key to proceed.\"
                                {
                                        send \003
                                        expect \"*?admin>\"
                                        alias_delete
                
                                }
                        \"*?admin>\"
                                {
                                        alias_delete
                                }
                        timeout
                                {
                                        exit
                                }
                        
                }
                expect eof"
#	echo "$com"
done
