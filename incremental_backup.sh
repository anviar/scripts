#!/bin/bash

bhost="backup@111.222.333.444"

dirs="/home/mysite1
/home/mysite2"

if [[ "$(date +%w)" -eq 0 ]] || [[ "$1" == "-f" ]]
then
	echo "$(date|tr -d "\n"): Begin FULL backup of files..."
	WORKDIR="~/weekly/${HOSTNAME}/$(date +%W)"
	BTYPE=full
else
	echo "$(date|tr -d "\n"): Begin incremental (only last day) backup of files..."
	WORKDIR="~/daily/${HOSTNAME}/$(date +%A)"
	BTYPE=incremental
fi

# Preparing folders
echo "$(date|tr -d "\n"): Clean..."
ssh ${bhost} "mkdir -p ${WORKDIR} ; cd ${WORKDIR} ; rm -f *.tar.bz2 *.tar.gz *.sql.bz2"

for cdir in ${dirs}
do
	if [[ "${BTYPE}" == "full" ]]
	then
		bname=$(echo "$cdir"|awk -F\/ '{print $3"-"$NF".tar.gz"}')
		echo "$(date|tr -d "\n"): Processing $cdir"
		tar -zPcf - ${cdir}|ssh ${bhost} "cat >${WORKDIR}/${bname}"
	else
		bname=$(echo "$cdir"|awk -F\/ '{print $3"-"$NF".tar.bz2"}')
		echo "$(date|tr -d "\n"): Processing $cdir"
		tar -jPcf - --newer-mtime '1 days ago' ${cdir}|ssh ${bhost} "cat >${WORKDIR}/${bname}"
	fi
done

echo "$(date|tr -d "\n"): Begin SQL backup..."

for cdb in $(mysql <<<"SHOW DATABASES;"|egrep -v "Database|information_schema|mysql|performance_schema")
do
	echo "$(date|tr -d "\n"): Processing $cdb"
	mysqldump $cdb|bzip2|ssh ${bhost} "cat >${WORKDIR}/${cdb}.sql.bz2"
done
