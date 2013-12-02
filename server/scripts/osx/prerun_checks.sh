#!/bin/sh
# Copyright (c) 2012-2013, EnterpriseDB Corporation.  All rights reserved

# test script for osx - check if system temp is writable and scripts can be executed from this path.

DIRNAME=`dirname $0`

# Check if temp path is writable 
TEMPFILE="$DIRNAME/test_temp.sh"
echo "a=1" > $TEMPFILE

if [ $? -ne 0 ];
then
    echo "Unable to write inside TEMP environment variable path."
    exit 1
fi

# check if we can run a script from temp folder
sh $TEMPFILE

if [ $? -ne 0 ];
then
    echo "Unable to execute from TEMP environment variable path."
    exit 2
fi

rm -f $TEMPFILE
exit 0
