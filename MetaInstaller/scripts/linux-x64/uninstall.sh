#!/bin/sh


if [ $# -ne 6 ]; then
         echo 1>&2 Usage: $0 true true true true true path
         exit 127
fi

if [ $2 = "true" ]; then
  $6/Slony/uninstall-slony --mode unattended
fi

if [ $3 = "true" ]; then
  $6/../pgJDBC/uninstall-pgjdbc --mode unattended
fi

if [ $4 = "true" ]; then
  $6/PostGIS/uninstall-postgis --mode unattended
fi

if [ $5 = "true" ]; then
  $6/../psqlODBC/uninstall-psqlodbc --mode unattended
fi


if [ $1 = "true" ]; then
  sudo $6/uninstall-postgresql --mode unattended
fi
