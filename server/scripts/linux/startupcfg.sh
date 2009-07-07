#!/bin/sh

# PostgreSQL startup configuration script for Linux
# Dave Page, EnterpriseDB

# Check the command line
if [ $# -ne 4 ]; 
then
    echo "Usage: $0 <Major.Minor version> <Username> <Install dir> <Data dir>"
    exit 127
fi

VERSION=$1
USERNAME=$2
INSTALLDIR=$3
DATADIR=$4

# Exit code
WARN=0

# Error handlers
_die() {
    echo $1
    exit 1
}

_warn() {
    echo $1
    WARN=2
}

# Write the startup script
cat <<EOT > "/etc/init.d/postgresql-$VERSION"
#!/bin/bash
#
# chkconfig: 2345 85 15
# description: Starts and stops the PostgreSQL $VERSION database server

# Source function library.
if [ -f /etc/rc.d/functions ];
then
    . /etc/init.d/functions
fi

# PostgreSQL Service script for Linux

start()
{
	echo \$"Starting PostgreSQL $VERSION: "
	su - $USERNAME -c "LD_LIBRARY_PATH=$INSTALLDIR/lib $INSTALLDIR/bin/pg_ctl -w start -D \"$DATADIR\" -l \"$DATADIR/pg_log/startup.log\""
	
	if [ $? -eq 0 ];
	then
		echo "PostgreSQL $VERSION started successfully"
                exit 0
	else
		echo "PostgreSQL $VERSION did not start in a timely fashion, please see $DATADIR/pg_log/startup.log for details"
                exit 1
	fi
}

stop()
{
	echo \$"Stopping PostgreSQL $VERSION: "
	su - $USERNAME -c "LD_LIBRARY_PATH=$INSTALLDIR/lib $INSTALLDIR/bin/pg_ctl stop -m fast -w -D \"$DATADIR\""
}

# See how we were called.
case "\$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart|reload)
        stop
        sleep 3
        start
        ;;
  condrestart)
        if [ -f "$DATADIR/postmaster.pid" ]; then
            stop
            sleep 3
            start
        fi
        ;;
  status)
        su - $USERNAME -c "LD_LIBRARY_PATH=$INSTALLDIR/lib $INSTALLDIR/bin/pg_ctl status -D \"$DATADIR\""
        ;;
  *)
        echo \$"Usage: $0 {start|stop|restart|condrestart|status}"
        exit 1
esac

EOT

# Fixup the permissions on the StartupItems
chmod 0755 "/etc/init.d/postgresql-$VERSION" || _warn "Failed to set the permissions on the startup script (/etc/init.d/postgresql-$VERSION/)"

_process_libs() {

  lib_dir=$1
  libname=$2

  # Remove the libraries that are already present in the system.
  cd $lib_dir	
  library_list=`ls $libname*`

  for library in $library_list
  do
     if [ -d "/lib64" ]
     then
       flag1=`ls /lib64/$library`
     else
       flag1=`ls /lib/$library`
     fi
     if [ -d "/usr/lib64" ]
     then
       flag2=`ls /usr/lib64/$library`
     else
       flag2=`ls /usr/lib/$library`
     fi
     # If found delete the library from the INSTALLDIR/lib 
     if [ "x$flag1" != "x" -o "y$flag2" != "y" ]
     then
           rm -f $library   || _die "Failed to remove the library $library"
     fi
  done

}

# Process server libs
_process_libs "$INSTALLDIR/lib" "libssl.so"
_process_libs "$INSTALLDIR/lib" "libcrypto.so"
_process_libs "$INSTALLDIR/lib" "libreadline.so"
_process_libs "$INSTALLDIR/lib" "libtermcap.so"
_process_libs "$INSTALLDIR/lib" "libuuid.so"


# Configure the startup. On Redhat and friends we use chkconfig. On Debian, update-rc.d
# These utilities aren't entirely standard, so use both from their standard locations on
# each distro family. 
RET=`type /sbin/chkconfig > /dev/null 2>&1 || echo fail`
if [ ! $RET ];
then
    /sbin/chkconfig --add postgresql-$VERSION
	if [ $? -ne 0 ]; then
	    _warn "Failed to configure the service startup with chkconfig"
	fi
fi

RET=`type /usr/sbin/update-rc.d > /dev/null 2>&1 || echo fail`
if [ ! $RET ];
then
    /usr/sbin/update-rc.d postgresql-$VERSION defaults
	if [ $? -ne 0 ]; then
	    _warn "Failed to configure the service startup with update-rc.d"
	fi
fi

# Setup shared libraries
if [ -d /etc/ld.so.conf.d ];
then
    echo "$INSTALLDIR/lib" > /etc/ld.so.conf.d/postgresql-$VERSION.conf || _warn "Failed to configure the shared library path"
else
    if [ -f /etc/ld.so.conf ]; 
    then
        RETVAL=`grep $INSTALLDIR/lib /etc/ld.so.conf | wc -l`
        if [ "x$RETVAL" = "x0" ];
        then
            echo "$INSTALLDIR/lib" >> /etc/ld.so.conf || _warn "Failed to configure the shared library path" 
        fi
    else
        echo "$INSTALLDIR/lib" > /etc/ld.so.conf || _warn "Failed to configure the shared library path" 
    fi
fi
ldconfig || _warn "Failed to run ldconfig"

echo "$0 ran to completion"
exit $WARN
