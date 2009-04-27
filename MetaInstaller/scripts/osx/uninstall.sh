#!/bin/sh


if [ $# -ne 9 ]; then
         echo 1>&2 Usage: $0 true true true true true true true true path
         exit 127
fi

if [ $2 = "true" ]; then
  $9/Slony/uninstall-slony.app/Contents/MacOS/installbuilder.sh --mode unattended
fi

if [ $3 = "true" ]; then
  $9/pgJDBC/uninstall-pgjdbc.app/Contents/MacOS/installbuilder.sh --mode unattended
fi

if [ $4 = "true" ]; then
  $9/PostGIS/uninstall-postgis.app/Contents/MacOS/installbuilder.sh --mode unattended
fi

if [ $5 = "true" ]; then
  $9/psqlODBC/uninstall-psqlodbc.app/Contents/MacOS/installbuilder.sh --mode unattended
fi

if [ $6 = "true" ]; then
  $9/pgbouncer/uninstall-pgbouncer.app/Contents/MacOS/installbuilder.sh --mode unattended
fi


if [ $7 = "true" ]; then
  sudo $9/uninstall-pgmemcache.app/Contents/MacOS/installbuilder.sh --mode unattended
fi

if [ $8 = "true" ]; then
  sudo $9/pgAgent/uninstall-pgagent.app/Contents/MacOS/installbuilder.sh --mode unattended
fi


if [ $1 = "true" ]; then
  sudo $9/uninstall-postgresql.app/Contents/MacOS/installbuilder.sh --mode unattended
fi
