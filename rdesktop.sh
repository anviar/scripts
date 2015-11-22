#!/bin/bash

#Проверяем наличие индивидуальных настроек
if [[ -f $HOME/.osrostov/rdp.conf ]] ; then
    source $HOME/.osrostov/rdp.conf
    creditionals="-u $user -p $password"
fi
#Определяем притер по-умолчанию
printer=$(lpstat -d|sed s/"system default destination: "//|sed s/"назначение системы по умолчанию: "// )

if [[ ! -z "$printer" ]] ; then
    printer_opt="-r printer:$printer"
fi
#Подбираем разрешение экрана
res=( $(xrandr |grep current|sed s/','//g|awk {'print $8" "$10'}) )
let res[0]=res[0]-10
let res[1]=res[1]-80
#Соединяемся
rdesktop -g ${res[0]}x${res[1]} -k en-us -N $printer_opt $creditionals 192.168.4.2

