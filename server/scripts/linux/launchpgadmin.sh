#!/bin/sh
# Copyright (c) 2012-2019, EnterpriseDB Corporation.  All rights reserved

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

  if [ ! -z "$SET_LDPRELOAD" ];
  then
     export eval ${SET_LDPRELOAD}
  fi
  LD_LIBRARY_PATH=PG_INSTALLDIR/pgAdmin3/lib:PG_INSTALLDIR/lib:$LD_LIBRARY_PATH G_SLICE=always-malloc PG_INSTALLDIR/pgAdmin3/bin/pgadmin3
