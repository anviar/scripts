#!/bin/bash

# Исползуйте sendxmpp из cvs!!!

maildir=/var/spool/mail
limit=100

cd ${maildir}

list=$(du -s *)

#echo -e "$list"
for i in $(echo -e "${list}"|awk {'print $2'})
do
    bsize=$(echo -e "${list}"|grep "$i"|awk {'print $1'})
    let "size=$bsize/1024"
    if [ ${size} -gt ${limit} ]
    then
	echo "Уважаемый(ая) $(ldapsearch -b ou=Users,dc=vip-driver,dc=ru uid=${i}|grep "^cn"|awk {'print $2'}|base64 -d),
Ваш почтовый ящик заполнен на ${size} мегабайт.
Немедленно очистите ящик от ненужной корреспонденции!
После удаления писем не забывайте очищать корзину.
=====================================================
P.S. Данное сообщение отправлено автоматом. Отвечать на него не нужно."|/usr/local/bin/sendxmpp -u guest -p qwe123 -j localhost:5222 ${i}@vip-driver.ru
    fi
done

