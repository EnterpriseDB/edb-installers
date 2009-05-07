#!/bin/sh

# PostgreSQL service user creation script for OSX
# Dave Page, EnterpriseDB

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
if [ "x`dscl . -list /users|cut -f2 -d' '|grep $1`" != "x" ];
then
    HOME_DIR=`su $1 -c "echo \\\$HOME"`
    if [ -e $HOME_DIR ]; then     
        echo "User account '$1' already exists"
        exit 0
    else
        echo "User account '$1' already exists - fixing non-existent home directory to $2"
        dscl . create /users/$1 home $2
        exit 0
    fi
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
    dscl . create /users/$1 realname "PostgreSQL"
fi

echo "$0 ran to completion"
exit 0
