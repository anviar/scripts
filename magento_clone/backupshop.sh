#!/bin/bash

WORKDIR=~/backup
FILES=~/public_html/domain
db=somedb
dbuser=somedbuser
dbpass=somedbpass

[[ -f ${WORKDIR}/domain.tar.bz2 ]] && rm -f ${WORKDIR}/domain.tar.bz2
cd ${FILES}
tar -jcf ${WORKDIR}/domain.tar.bz2 *

cd ${WORKDIR}
mysqldump -u${dbuser} -p${dbpass} ${db}|bzip2 > ${WORKDIR}/${db}.sql.bz2
