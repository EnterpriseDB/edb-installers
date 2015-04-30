#!/bin/sh
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL service user creation script for OSX

#Check the command line
if [ $# -ne 2 ]; 
then
    echo "Usage: $0 <Username> <Home directory>"
    exit 127
fi

# Error handler
_die() {
    echo "The service user account '$1' could not be created."
    exit 1
}

# Create the user account if required
if [ "x`dscl . -list /users|cut -f2 -d' '|grep ^$1$`" != "x" ];
then
    echo "User account '$1' already exists"
    exit 0
else
    NEWUID=`dscl . list /users uid | awk -F: '{FS=" "; print $2f}' | sort -n | tail -1`
    NEWUID=`expr $NEWUID + 1`
    dscl . create /users/$1 || _die $1
    dscl . create /users/$1 name $1
    dscl . create /users/$1 passwd "*"
    dscl . create /users/$1 uid $NEWUID
    dscl . create /users/$1 gid 1
    dscl . create /users/$1 home $2
    dscl . create /users/$1 shell /bin/bash
    dscl . create /users/$1 realname "pgAgent"
fi

echo "$0 ran to completion"
exit 0
