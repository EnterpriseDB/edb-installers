#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

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


# Create the user account if required
if [ "x`cat /etc/passwd|cut -f1 -d':'|grep ^$1$`" != "x" ];
then
    echo "User account '$1' already exists"
    exit 0
else

    # Create the group if required
    if [ "x`cat /etc/group|cut -f1 -d':'|grep ^$1$`" = "x" ];
    then
        groupadd $1 || _die $1
    fi
 
    useradd -m -c "PostgreSQL" -d "$2" -g $1 $1 || _die $1

fi

echo "$0 ran to completion"
exit 0
