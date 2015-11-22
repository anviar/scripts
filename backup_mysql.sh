#!/bin/bash

export LANG=POSIX

date

#Настройки
PREFIX=/var/backups/MySQL
mysql_user="muser"
mysql_password="mpass"
ftp_host="111.222.333.444"
ftp_user="fuser"
ftp_passwd="fpass"
ftp_workdir="$(date +%y%m%d)"
backup_depth=21
ftp_expired_dir=$(date +%y%m%d -d "${backup_depth} days ago")
pgp_id="enter id-num"

ftp_base_chat="user ${ftp_user} ${ftp_passwd}
binary
cd MySQL
mkdir ${ftp_workdir}
cd ${ftp_workdir}
"
bases=$(mysql -u ${mysql_user} -p${mysql_password} -e "SHOW DATABASES;")

dir=${PREFIX}/$(date +%d%b%y)
mkdir -p ${dir}
cd ${dir}

for cdb in ${bases}
do

    if [ "${cdb}" != "Database" ]&&[ "${cdb}" != "information_schema" ]&&[ "${cdb}" != "mysql" ]
    then
            echo "Обрабатываю ${cdb}..."
            file_sql=${dir}/${cdb}.sql
            if [ ! -f ${file_sql}.bz2 ] && [ ! "${cdb}" == "null" ] ; then
                mysqldump -h 127.0.0.1 -u ${mysql_user} --password="${mysql_password}" ${cdb}>${file_sql}
                #bzip2 -z ${file_sql}
		#gpg --batch --recipient "${pgp_id}" --encrypt ${file_sql}.bz2
		#rm -f ${file_sql}.bz2
            fi
    
    fi
done

echo "Конец обработки."
echo "Загрузка файлов на удаленный сервер..."
for cf in $(ls *.gpg) ; do
	ready_files="put ${cf}
${ready_files}"
done

ftp_expired_files=$(ftp -n ${ftp_host} << EOF
user ${ftp_user} ${ftp_passwd}
binary
cd MySQL
cd ${ftp_expired_dir}
ls 
bye
EOF
)

ftp_expired_files=$(echo "${ftp_expired_files}"|awk {'print "delete " $9'})
ftp -n ${ftp_host} << EOF
${ftp_base_chat}
${ready_files}
cd ..
cd ${ftp_expired_dir}
${ftp_expired_files}
cd ..
rmdir ${ftp_expired_dir}
bye
EOF
echo "Загрузка завершена"

#Очистка хлама
find ${PREFIX} -maxdepth 1 -ctime +${backup_depth} -name "[0-3][0-9][A-Z][a-z][a-z][0-1][0-9]" -exec rm -rf {} \;

date

