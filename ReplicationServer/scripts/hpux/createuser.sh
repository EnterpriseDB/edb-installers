#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# xDB Replication service user creation script for HPUX

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
groupadd $1
RVAL=$?
if [ $RVAL != 0 ]; then
  if [ $RVAL != 4 -a $RVAL != 9 ]; then
    _die $1
  fi
fi

# Create the user account if required
useradd -m -c "xDBReplication" -g $1 $1
RVAL=$?
if [ $RVAL != 0 ]; then
  if [ $RVAL != 4 -a $RVAL != 9 -a $RVAL != 10 ]; then
    _die $1
  fi
fi

if [ $RVAL = 0 ]; then
  usermod -p "*" $1
elif [ $RVAL = 10  ]; then
  userdel $1 > /dev/null 2>&1
  echo "Can not create user, NIS group is specified."
  _die $1
fi

HOME_DIR=`su - $1 -c "echo \\\$HOME" | tail -2 | head -1`
HOME_DIR=`echo $HOME_DIR | sed '1,/\//s/\//#/' | awk -F# '{print $2}' | sed 's/^/\//'`
if [ ! -e "$HOME_DIR" ]; then
     echo "User account '$1' already exists - fixing non-existent home directory to $HOME_DIR"
     usermod -d "$HOME_DIR" $1
     exit 0
fi

echo "$0 ran to completion"
exit 0
