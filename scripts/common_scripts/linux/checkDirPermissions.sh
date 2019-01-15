#!/bin/bash
# Copyright (c) 2012-2019, EnterpriseDB Corporation.  All rights reserved
# This script accepts a path, which it traverses and checks if 'others' users have
# read & execute permissions. If any of the directory do not have the permissions
# then it will echo "100" and exit.

parts=`echo $1 | awk 'BEGIN{FS="/"}{for (i=1; i < NF; i++) print $i}'`

for part in $parts
do
        path="$path/$part"
	if [ -d $path ]; then
                if [ `ls -ld $path | awk '{print $1}' | awk '{ print substr( $0, 8) }' | grep r` ] && [[ `ls -ld $path | awk '{print $1}' | awk '{ print substr( $0, 8) }' | grep x` || `ls -ld $path | awk '{print $1}' | awk '{ print substr( $0, 8) }' | grep t` ]]; then
                        :
                        #echo "read & execute permissions for others to $path \n"
                else
                        #echo "No read & execute permissions for others to $path \n"
                        echo 100
                        exit
                fi
        fi
done
