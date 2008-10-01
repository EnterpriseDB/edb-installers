#!/bin/bash

#Changing refernece of the so file
sudo install_name_tool -change "libpq.5.dylib" "$1/lib/libpq.5.dylib" "$1/lib/psqlodbcw.so"
