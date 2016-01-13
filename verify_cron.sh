#!/bin/bash

TMPUSER=crontest

if [[ -z $1 ]]
then
	CRON_FILE=/etc/crontab
else 
	if [[ -f $1 ]]
	then
		CRON_FILE=$1
	else
		echo "Error: $1 not found"
		exit 1
	fi
fi

id ${TMPUSER} >>/dev/null 2>/dev/null
if [[ $? -ne 0 ]]
then
	echo "Info: creating test-user ${TMPUSER}"
	useradd ${TMPUSER} -s /sbin/nologin
fi

if [[ -f ${CRON_FILE} ]]
then
	cat ${CRON_FILE}|crontab -u ${TMPUSER} -
	[[ $? -eq 0 ]] && echo "${CRON_FILE} is OK" || echo -e "ERROR in ${CRON_FILE}"
	crontab -u ${TMPUSER} -r 2>>/dev/null
else
	echo "Error: ${CRON_FILE} not found"
fi