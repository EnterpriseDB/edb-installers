#!/bin/sh
# Check if certificate file is passed as argument or not which is optional
CERTPATH=""
usage() { echo "Usage: $0 [-c <ca-bundle certificate path> ]" 1>&2; exit 1; }

OPTS=`getopt -o c: --long ca-bundle: -n 'parse-options' -- "$@"`
if [ $? != 0 ] ; then usage; fi
eval set -- "$OPTS"
while true; do
  case "$1" in
    -c | --ca-bundle )
            if [ -f $2 ]; then
                CERTPATH="-c $2";
        else
                echo "ca-bundle certificate file '$2' does not exist"
                usage
                exit 1;
        fi
        shift; shift;;

    * ) break ;;
  esac
done

# PostgreSQL stackbuilder runner script for Linux
# Dave Page, EnterpriseDB
LOADINGUSER=`whoami`
echo "No graphical su/sudo program could be found on your system!"
echo "This window must be kept open while Stack Builder is running."
echo ""

# You're not running this script as root user
if [ x"$LOADINGUSER" != x"root" ];
then

    USE_SUDO=0

    if [ -f /etc/lsb-release ];
    then
        if [ `grep -E '^DISTRIB_ID=[a-zA-Z]?buntu$' /etc/lsb-release | wc -l` != "0" ];
        then
            USE_SUDO=1
        fi
    fi

    if [ $USE_SUDO != "1" ];
    then
        echo "Please enter the root password when requested."
    else
        echo "Please enter your password if requested."
    fi

    if [ $USE_SUDO = "1" ];
    then
        sudo su - -c "LD_LIBRARY_PATH="PG_INSTALLDIR/stackbuilder/lib":"PG_INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder" $CERTPATH"
    else
        su - -c "LD_LIBRARY_PATH="PG_INSTALLDIR/stackbuilder/lib":"PG_INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder" $CERTPATH"
    fi

else
    LD_LIBRARY_PATH="PG_INSTALLDIR/stackbuilder/lib":"PG_INSTALLDIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "PG_INSTALLDIR/stackbuilder/bin/stackbuilder" $CERTPATH
fi

# Wait a while to display su or sudo invalid password error if any
if [ $? -eq 1 ];
then
    sleep 2
fi

