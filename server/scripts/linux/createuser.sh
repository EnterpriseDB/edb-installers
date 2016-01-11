#!/bin/sh
# Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL server service user creation script for Linux

# Check the command line
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


# Create the group if required
if ! getent group $1 > /dev/null
then
    groupadd $1 || _die $1
fi

MSG=""
# Create the user account if required
if getent passwd $1 > /dev/null
then

    HOME_DIR=`su $1 -c "echo \\\$HOME"`
    if [ -e $HOME_DIR ]; then
       MSG="User account '$1' already exists"
    else
        MSG="User account '$1' already exists - fixing non-existent home directory to $2"
        usermod -d "$2" $1
    fi
   
else
	useradd -m -c "PostgreSQL" -d "$2" -g $1 $1 || _die $1
	usermod -p "*" $1
	MSG="$0 ran to completion"
fi

echo "$MSG"

#Add a raise condition for creation of $HOME/.cache folder
#As a part of centos 7 and RHL 7 and above , new user try to create .cache folder in $HOME/.cache
#Since parent folder is own by root and read only it would take care.
mkdir -p "$2/.cache" || _die $1
chown $1:$1 "$2/.cache" || _die $1

exit 0
