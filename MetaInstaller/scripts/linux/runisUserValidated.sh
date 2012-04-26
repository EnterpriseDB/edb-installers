#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved


LD_LIBRARY_PATH="$1/lib" "$1/isUserValidated.o" "$2" "$3" "$4"

exit $?
