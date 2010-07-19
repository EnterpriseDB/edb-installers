#!/bin/bash

# PostgreSQL pg_controldata runner script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 2 ]; 
then
    echo "Usage: $0 <Temp directory> <Data directory>"
    exit 127
fi

LD_LIBRARY_PATH=$1/lib:/usr/sfw/lib/64 $1/pg_controldata $2

exit $?

