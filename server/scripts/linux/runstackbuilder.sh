#!/bin/sh
# Copyright (c) 2012-2022, EnterpriseDB Corporation.  All rights reserved

usage() {
  echo "Usage: $0 [-h] [-m <str>] [-a <str>] [-d <str>] [-l <str>] [-c <str>]"
  echo "-h, --help                  	show this help message"
  echo "-m, --mirror-list <str>     	download the mirror list from the specified URL"
  echo "-a, --application-list <str>	download the application list from the specified URL"
  echo "-d, --download-counter <str>	use the download counter at the specified URL"
  echo "-l, --language <str>        	use the specified language in the UI"
  echo "-c, --ca-bundle <str>       	user certificate for https support from the specified URL"
  exit 1;
}

COMMAND_LINE_ARGS=""
MIRROR_LIST=""
APPLICATION_LIST=""
DOWNLOAD_COUNTER=""
LANGUAGE=""
CA_BUNDLE=""

OPTS=$(getopt -n 'parse-options' -o "h:m:a:d:l:c:" --long "mirror-list:,application-list:,download-counter:,language:,ca-bundle:,help:" -- "$@")
if [ $? != 0 ] ; then usage; fi
eval set -- "$OPTS"

while true; do
  case "$1" in
    -h | --help )
         usage;
         ;;
    -m | --mirror-list )
         MIRROR_LIST="-m $2";
         shift 2
         ;;
    -a | --application-list )
         APPLICATION_LIST="-a $2";
         shift 2
         ;;
    -d | --download-counter )
         DOWNLOAD_COUNTER="-d $2"
         shift 2
         ;;
    -l | --language )
         LANGUAGE="-l $2"
         shift 2
         ;;
    -c | --ca-bundle )
         if [ -f $2 ]; then
           CA_BUNDLE="-c $2" ;
         else
           echo "ca-bundle certificate file '$2' does not exist"
           exit 1
         fi
         shift 2
         ;;
     --) shift; break ;;
     *)
           usage
           break ;;
  esac
done

COMMAND_LINE_ARGS="$MIRROR_LIST $APPLICATION_LIST $DOWNLOAD_COUNTER $LANGUAGE $CA_BUNDLE"

# PostgreSQL stackbuilder runner script for Linux
# Dave Page, EnterpriseDB
LOADINGUSER=`whoami`
echo "No graphical su/sudo program could be found on your system!"
echo "This window must be kept open while Stack Builder is running."
echo ""

#Is it Ubuntu?
if [ -f /etc/lsb-release ];
then
    if [ `grep -E '^DISTRIB_ID=[a-zA-Z]?buntu$' /etc/lsb-release | wc -l` != "0" ];
    then
        ISIT_UBUNTU=1
        #libpng causes the issue while launching the Stackbuilder as it has dependecny on libz so used the LD_PRELOAD variable to launch it without any issues.
        UBUNTU_VERSION=`grep DISTRIB_RELEASE /etc/lsb-release | cut -d "=" -f2 | cut -d "." -f1`
        if [ "$UBUNTU_VERSION" -ge "17" ];
        then
            LD_PRELOAD="/lib/x86_64-linux-gnu/libz.so.1"
        fi
    fi
fi

# You're not running this script as root user
if [ x"$LOADINGUSER" != x"root" ];
then

   USE_SUDO=0

   if [ ! -z $ISIT_UBUNTU ];
   then
       USE_SUDO=1
   fi

    if [ $USE_SUDO != "1" ];
    then
        echo "Please enter the root password when requested."
    else
        echo "Please enter your password if requested."
    fi

    if [ $USE_SUDO = "1" ];
    then
        sudo su - -c "LD_PRELOAD="$LD_PRELOAD" LD_LIBRARY_PATH="PG_INSTALLDIR/stackbuilder/lib":"PG_INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder" $COMMAND_LINE_ARGS"
    else
        su - -c "LD_LIBRARY_PATH="PG_INSTALLDIR/stackbuilder/lib":"PG_INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder" $COMMAND_LINE_ARGS"
    fi

else
    LD_PRELOAD="$LD_PRELOAD" LD_LIBRARY_PATH="PG_INSTALLDIR/stackbuilder/lib":"PG_INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder" $COMMAND_LINE_ARGS
fi

# Wait a while to display su or sudo invalid password error if any
if [ $? -eq 1 ];
then
    sleep 2
fi

