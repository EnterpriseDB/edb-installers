#!/bin/sh
# Copyright (c) 2012-2020, EnterpriseDB Corporation.  All rights reserved

#Is it Ubuntu?
uname -a | grep -i ubuntu > /dev/null
if [ "$?" -eq "0" ]
then
    #assuming /etc/lsb-release is always present on Ubuntu
    #libpng causes the issue while launching the pgAdmin as it has dependecny on libz so used the LD_PRELOAD variable to launch it without any issues.
    UBUNTU_VERSION=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f2 | cut -d "." -f1`
    if [ "$UBUNTU_VERSION" -ge "17" ];
    then
       SET_LDPRELOAD="LD_PRELOAD=/lib/x86_64-linux-gnu/libz.so.1"

    fi
fi

#Is it Fedora?
if [ -f /etc/fedora-release ];
then
    FEDORA_VERSION=`cat /etc/fedora-release | cut -d " " -f3`
    #libpng causes the issue while launching the pgAdmin as it has dependecny on libz so used the LD_PRELOAD variable to launch it without any issues
    if [ "$FEDORA_VERSION" -ge "28" ];
    then
        SET_LDPRELOAD="LD_PRELOAD=/lib64/libz.so.1"
    fi
fi

  if [ ! -z "$SET_LDPRELOAD" ];
  then
     export eval ${SET_LDPRELOAD}
  fi
  LD_LIBRARY_PATH="PG_INSTALLDIR/lib:PG_INSTALLDIR/pgAdmin 4/venv/lib:PG_INSTALLDIR/pgAdmin 4/lib:PG_INSTALLDIR/stackbuilder/lib:$LD_LIBRARY_PATH" "PG_INSTALLDIR/pgAdmin 4/bin/pgAdmin4"
