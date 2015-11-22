#!/bin/bash

#Для корректной работы приложения необходимы пакеты 
#	x11-misc/gtkdialog
#	sys-fs/cryptsetup
#	app-admin/sudo


source $HOME/.osrostov/crypt.conf

if [[ -b $crypt_dev ]] && [[ ! -b /dev/mapper/cryptD ]] ; then
export MAIN_DIALOG='
<vbox>
  <entry>
    <variable>pass</variable>
    <visible>password</visible>
  </entry>
  <button>
    <label>Открыть</label>
  </button>
</vbox>
'
    crypt_pass=$(gtkdialog --program $MAIN_DIALOG|grep pass|awk -F = {'print $2'}|sed 's/"//g')
    echo "$crypt_pass"|/usr/bin/sudo /sbin/cryptsetup luksOpen $crypt_dev cryptD
    if [[ ! -b /dev/mapper/cryptD ]] ; then
	export MAIN_DIALOG='
	    <vbox>
		<text>
	    	    <label>Неверный пароль!</label>
		</text>
	    </vbox>  
		'
	gtkdialog --program $MAIN_DIALOG
	exit 0
    fi
else
	export MAIN_DIALOG='
	    <vbox>
		<text>
	    	    <label>Неверно указано устройство или оно уже смонтировано!</label>
		</text>
	    </vbox>  
		'
	gtkdialog --program $MAIN_DIALOG
	exit 0
fi

mount /mnt/cryptD
if [[ -z $(mount|grep /mnt/crypt) ]] ; then
	export MAIN_DIALOG='
	    <vbox>
		<text>
	    	    <label>Ошибка монтирования! Доступ к устройству закрыт!</label>
		</text>
	    </vbox>  
    		'
	/usr/bin/sudo /sbin/cryptsetup luksClose cryptD
	gtkdialog --program $MAIN_DIALOG
fi

