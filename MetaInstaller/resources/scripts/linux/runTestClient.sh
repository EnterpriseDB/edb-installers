#!/bin/sh


# Check the command line
if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <Temp directory> "
    exit 127
fi

LD_LIBRARY_PATH="$1/lib" "$1/mytestClient.o"

exit $?
