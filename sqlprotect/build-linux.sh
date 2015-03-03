#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_sqlprotect_linux() {
    
    echo "BEGIN PREP sqlprotect Linux"
 
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
   
    echo "END PREP sqlprotect Linux"	
}

################################################################################
# Build
################################################################################

_build_sqlprotect_linux() {
    
    echo "BEGIN BUILD sqlprotect Linux"  
    
    ssh $PG_SSH_LINUX "cd $PG_PATH_LINUX/server/source/postgres.linux/contrib/SQLPROTECT/; make distclean ; make" || _die "Failed to build sqlprotect"
	
    ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/sqlprotect/staging/linux/lib/postgresql" || _die "Failed to create staging/linux/lib/postgresql"
	ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/sqlprotect/staging/linux/share" || _die "Failed to create staging/linux/share"
    ssh $PG_SSH_LINUX "mkdir -p $PG_PATH_LINUX/sqlprotect/staging/linux/doc" || _die "Failed to create staging/linux/doc"

    ssh $PG_SSH_LINUX "cp $PG_PATH_LINUX/server/source/postgres.linux/contrib/SQLPROTECT/sqlprotect.so $PG_PATH_LINUX/sqlprotect/staging/linux/lib/postgresql/" || _die "Failed to copy sqlprotect.so to staging directory"
	ssh $PG_SSH_LINUX "cp $PG_PATH_LINUX/server/source/postgres.linux/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_LINUX/sqlprotect/staging/linux/share/" || _die "Failed to copy sqlprotect.sql to staging directory"
	ssh $PG_SSH_LINUX "cp $PG_PATH_LINUX/server/source/postgres.linux/contrib/SQLPROTECT/README-sqlprotect.txt $PG_PATH_LINUX/sqlprotect/staging/linux/doc/" || _die "Failed to copy README-sqlprotect.txt to staging directory"

    chmod -R ugo+r $WD/sqlprotect/staging/linux
    
    cp $WD/sqlprotect/resources/licence.txt $WD/sqlprotect/staging/linux/sqlprotect_license.txt || _die "Unable to copy sqlprotect_license.txt"
    chmod 444 $WD/sqlprotect/staging/linux/sqlprotect_license.txt || _die "Unable to change permissions for license file"

    echo "END BUILD sqlprotect Linux"
}


################################################################################
# Post process
################################################################################

_postprocess_sqlprotect_linux() {
    
    echo "BEGIN POST sqlprotect Linux"

    cd $WD/sqlprotect

    # Set permissions to all files and folders in staging
    _set_permissions linux
    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

    echo "END POST sqlprotect Linux"
}

