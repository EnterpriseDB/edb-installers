#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_sqlprotect_linux() {

    cd $WD/server/source
	
    # Remove any existing sqlprotect directory that might exist, in server
    if [ -e postgres.linux/contrib/SQLPROTECT ];
    then
      echo "Removing existing sqlprotect directory"
      rm -rf postgres.linux/contrib/SQLPROTECT || _die "Couldn't remove the existing sqlprotect directory"
    fi

    # create a copy of the sqlprotect tree
	cd postgres.linux/contrib
    git clone ssh://pginstaller@cvs.enterprisedb.com/git/SQLPROTECT
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/linux ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/linux || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/sqlprotect/staging/linux)"
    mkdir -p $WD/sqlprotect/staging/linux/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/linux || _die "Couldn't set the permissions on the staging directory"
	
}

################################################################################
# Build
################################################################################

_build_sqlprotect_linux() {

    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/SQLPROTECT/; make distclean ; make" || _die "Failed to build sqlprotect"
	
    ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/sqlprotect/staging/linux/lib/postgresql" || _die "Failed to create staging/linux/lib/postgresql"
	ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/sqlprotect/staging/linux/share" || _die "Failed to create staging/linux/share"
    ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/sqlprotect/staging/linux/doc" || _die "Failed to create staging/linux/doc"

    ssh $PG_SSH_LINUX "cp $PG_PATH_LINUX/server/source/postgres.linux/contrib/SQLPROTECT/sqlprotect.so $PG_PATH_LINUX/sqlprotect/staging/linux/lib/postgresql/" || _die "Failed to copy sqlprotect.so to staging directory"
	ssh $PG_SSH_LINUX "cp $PG_PATH_LINUX/server/source/postgres.linux/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_LINUX/sqlprotect/staging/linux/share/" || _die "Failed to copy sqlprotect.sql to staging directory"
	ssh $PG_SSH_LINUX "cp $PG_PATH_LINUX/server/source/postgres.linux/contrib/SQLPROTECT/README-sqlprotect.postgresql $PG_PATH_LINUX/sqlprotect/staging/linux/doc/README.sqlprotect" || _die "Failed to copy README-sqlprotect.postgresql to staging directory"
    chmod -R ugo+r $WD/sqlprotect/staging/linux

}


################################################################################
# Post process
################################################################################

_postprocess_sqlprotect_linux() {

    cd $WD/sqlprotect

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD
}

