#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL psql runner script for Linux

# Check the command line
if [ $# -ne 0 -a $# -ne 1 ]; 
then
    echo "Usage: $0 [wait]"
    exit 127
fi

validate_port()
{

  port=$1   
  
  nodigits=`echo $port | sed 's/[[:digit:]]//g'`
  
  if [ ! -z $nodigits ] ; then
       echo "Invalid port specified." 
       return 1
  fi
  
  if [ "$port" -le 0 ] ; then
       echo "Port specified must be greater than 0." 
       return 1
  fi
  if [ "$port" -ge 65535 ] ; then
       echo "Port specified must be less than 65535." 
       return 1
  fi
  return 0
}

echo -n "Server [localhost]: "
read SERVER

if [ "$SERVER" = "" ];
then
    SERVER="localhost"
fi

echo -n "Database [postgres]: "
read DATABASE

if [ "$DATABASE" = "" ];
then
    DATABASE="postgres"
fi

echo -n "Port [PG_PORT]: "
read PORT

if [ "$PORT" = "" ];
then
    PORT="PG_PORT"
fi

echo -n "Username [PG_USERNAME]: "
read USERNAME

if [ "$USERNAME" = "" ];
then
    USERNAME="PG_USERNAME"
fi

validate_port $PORT 

if [ $? = 0 ];
then
    # If there's an OS supplied version of libreadline, try to make use of it,
    # as it's more reliable than libedit, which we link with.
    PLL=""
    if [ -f /lib64/libreadline.so.6 ];
    then
        PLL=/lib64/libreadline.so.6:
    fi
    if [ -f /lib/libreadline.so.6 ];
    then
        PLL=$PLL:/lib/libreadline.so.6:
    fi

    if [ -z "$LD_PRELOAD" ];
    then
        "PG_INSTALLDIR/bin/psql" -h $SERVER -p $PORT -U $USERNAME $DATABASE
    else
        LD_PRELOAD=$PLL "PG_INSTALLDIR/bin/psql" -h $SERVER -p $PORT -U $USERNAME $DATABASE
	fi
    RET=$?
else
    RET=1
fi

if [ "$RET" != "0" ];
then
    echo
    echo -n "Press <return> to continue..."
    read dummy
fi

exit $RET
