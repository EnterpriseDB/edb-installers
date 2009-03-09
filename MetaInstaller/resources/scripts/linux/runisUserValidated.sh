#!/bin/sh


LD_LIBRARY_PATH="$1/lib" "$1/isUserValidated.o" "$2"

exit $?
