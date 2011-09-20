#!/bin/bash

if [ $# -ne 2 ];
then 
    echo "Usage: $0 <installer.xml.in> <i18n>"
    exit 127
fi

installerFile=$1
i18nFile=$2

msgInInstaller=`sed 's/^.*\${msg(\(.*\))}.*$/###\1/' $installerFile  | grep "###" | sed 's/^###\(.*\)/\1/' | sort | uniq | grep -v "Installer"`
msgInI18n=`sed -e '/^$/d' -e 's/^\([a-zA-Z._0-9\-]*\)=.*$/\1/' $i18nFile  | sort | uniq | grep -v "Installer" | grep -v "registration_plus" | grep -v "internet.con.title"`

i=1
echo "Testing for i18n tokens not described in i18n file .. "
for token in $msgInInstaller
do
    found=0
    for msg in $msgInI18n
    do
	if [ $token = $msg ];
	then
	    found=1
	fi
    done
    if [ $found -eq 0 ];
    then
	echo "        $i) $token"
	i=`expr $i + 1`
    fi
done
echo " "
i=1
echo "Testing for i18n tokens not used in installer.xml.in file but described in i18n file.. "
for msg in $msgInI18n
do
    found=0
    for token in $msgInInstaller
    do
	if [ $token = $msg ];
	then
	    found=1
	fi
    done
    if [ $found -eq 0 ];
    then
	echo "        $i) $msg"
	i=`expr $i + 1`
    fi
done
echo " "
