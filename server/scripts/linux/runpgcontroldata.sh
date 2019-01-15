#!/bin/sh
# Copyright (c) 2012-2019, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL pg_controldata runner script for Linux

# Check the command line
if [ $# -ne 2 ]; 
then
    echo "Usage: $0 <Temp directory> <Data directory>"
    exit 127
fi

LD_LIBRARY_PATH=$1/lib $1/pg_controldata $2

exit $?

