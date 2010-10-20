#!/bin/sh

# test script for linux - check if system temp is writable and scripts can be executed from this path.
# Dave Page, EnterpriseDB

# Check if temp path is writable 
echo "a=1" > /tmp/test_temp.sh

if [ $? -ne 0 ];
then
    echo "Unable to write inside TEMP environment variable path."
    exit 1
fi

# check if we can run a script from temp folder
sh /tmp/test_temp.sh

if [ $? -ne 0 ];
then
    echo "Unable to execute from TEMP environment variable path."
    exit 2
fi

`rm -f /tmp/test_temp.sh`
exit 0
