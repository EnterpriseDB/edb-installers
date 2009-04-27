#!/bin/sh


if [ $# -ne 9 ]; then
         echo 1>&2 Usage: $0 true true true true true true true true path
         exit 127
fi

if [ $2 = "true" ]; then
  $9/Slony/uninstall-slony --mode unattended
fi

if [ $3 = "true" ]; then
  $9/pgJDBC/uninstall-pgjdbc --mode unattended
fi

if [ $4 = "true" ]; then
  $9/PostGIS/uninstall-postgis --mode unattended
fi

if [ $5 = "true" ]; then
  $9/psqlODBC/uninstall-psqlodbc --mode unattended
fi

if [ $6 = "true" ]; then
  $9/pgbouncer/uninstall-pgbouncer --mode unattended
fi


if [ $7 = "true" ]; then
  sudo $9/uninstall-pgmemcache --mode unattended
fi

if [ $8 = "true" ]; then
  sudo $9/pgAgent/uninstall-pgagent --mode unattended
fi

if [ $1 = "true" ]; then
  sudo $9/uninstall-postgresql --mode unattended
fi
