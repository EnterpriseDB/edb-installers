#!/bin/sh


LD_LIBRARY_PATH="$1/lib" "$1/dynaTuneClient.o" "$2" "$3" "$4" "$5" "$6"

exit $?
