#!/bin/bash

# Perferences
WEBROOT=~/public_html/domain.com
WORKDIR=~/shadowcopy
SHOST=someftphost.com
ftpuser=someftpuser
ftppass=somepassword
db=somedatabase
dbuser=somedbuser
dbpass=somedbpass
sqlfile=domain.sql.bz2
datafile=domain.tar.bz2
SRCDOMAIN=src.domain.com
DSTDOMAIN=dst.domain.com

# ==== Let's begin ====

# Download last backup
echo "$(date|tr -d "\n"): Downloading..."
cd ${WORKDIR}
rm -f ${sqlfile}
rm -f ${datafile}
wget --quiet --user="$ftpuser" --password="$ftppass" ftp://$SHOST/backup/*.bz2
if [[ $? -ne 0 ]] ; then
        echo "$(date|tr -d "\n"): Error: Can not download files!"
        exit 1
fi

echo "$(date|tr -d "\n"): Clean database..."
# Cleaning database
CLEAN_SQL="SET FOREIGN_KEY_CHECKS=0;"
for table in $(mysql -u${dbuser} -p${dbpass} $db <<< 'SHOW TABLES;'|grep -v Tables_in_shop)
do
	CLEAN_SQL="${CLEAN_SQL}DROP TABLE $table;"
done
CLEAN_SQL="${CLEAN_SQL}SET FOREIGN_KEY_CHECKS=1;"
mysql -u${dbuser} -p${dbpass} $db -e "$CLEAN_SQL" >>/dev/null

if [[ $? -ne 0 ]] ; then
	echo "$(date|tr -d "\n"): Error: DB cannot be cleared!"
	exit 1
fi

echo "$(date|tr -d "\n"): Restoring database..."
# Restoring DB from last backup
bunzip2 < ${WORKDIR}/${sqlfile} | mysql -u${dbuser} -p${dbpass} $db

mysql -u$dbuser -p$dbpass $db -e "UPDATE core_config_data SET value=REPLACE(value, \"${SRCDOMAIN}\", \"${DSTDOMAIN}\") WHERE path=\"web/secure/base_url\" OR path=\"web/unsecure/base_url\";"

echo "$(date|tr -d "\n"): Clean files..."
# Cleaning site root
if [[ ! -d ${WEBROOT} ]]
then
	echo "$(date|tr -d "\n"): Warning: Direcrory ${WEBROOT} does not exist!"
	mkdir -p ${WEBROOT}
else
	rm -rf ${WEBROOT}/*
fi

echo "$(date|tr -d "\n"): Restoring files..."
# Unpack last backup of files
cd ${WEBROOT}
tar -jxf ${WORKDIR}/${datafile}
# Clean cache and sessions
rm -rf ${WEBROOT}/var/cache/mage--*
rm -f ${WEBROOT}/var/session/sess_*

echo "$(date|tr -d "\n"): Completed."
