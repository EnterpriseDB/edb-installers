#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_sqlprotect_linux_x64() {

    cd $WD/server/source
	
    # Remove any existing sqlprotect directory that might exist, in server
    if [ -e postgres.linux-x64/contrib/SQLPROTECT ];
    then
      echo "Removing existing sqlprotect directory"
      rm -rf postgres.linux-x64/contrib/SQLPROTECT || _die "Couldn't remove the existing sqlprotect directory"
    fi

    # create a copy of the sqlprotect tree
	cd postgres.linux-x64/contrib
    git clone ssh://pginstaller@cvs.enterprisedb.com/git/SQLPROTECT
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/sqlprotect/staging/linux-x64)"
    mkdir -p $WD/sqlprotect/staging/linux-x64/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"
	
}

################################################################################
# Build
################################################################################

_build_sqlprotect_linux_x64() {

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/; make distclean ; make" || _die "Failed to build sqlprotect"
	
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/lib/postgresql" || _die "Failed to create staging/linux-x64/lib/postgresql"
	ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/share" || _die "Failed to create staging/linux-x64/share"
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/doc" || _die "Failed to create staging/linux-x64/doc"

    ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/sqlprotect.so $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/lib/postgresql/" || _die "Failed to copy sqlprotect.so to staging directory"
	ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/share/" || _die "Failed to copy sqlprotect.sql to staging directory"
	ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/README-sqlprotect.postgresql $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/doc/README.sqlprotect" || _die "Failed to copy README-sqlprotect.postgresql to staging directory"
    chmod -R ugo+r $WD/sqlprotect/staging/linux-x64

}


################################################################################
# Post process
################################################################################

_postprocess_sqlprotect_linux_x64() {

    cd $WD/sqlprotect

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
}
