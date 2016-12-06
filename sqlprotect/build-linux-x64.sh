#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_sqlprotect_linux_x64() {
    
    echo "BEGIN PREP sqlprotect Linux-x64"

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
   
    echo "END PREP sqlprotect Linux-x64"	
}

################################################################################
# Build
################################################################################

_build_sqlprotect_linux_x64() {
    
    echo "BEGIN BUILD sqlprotect Linux-x64"

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/; make distclean ; make" || _die "Failed to build sqlprotect"
	
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/lib/postgresql" || _die "Failed to create staging/linux-x64/lib/postgresql"
	ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/share" || _die "Failed to create staging/linux-x64/share"
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/doc" || _die "Failed to create staging/linux-x64/doc"

    ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/sqlprotect.so $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/lib/postgresql/" || _die "Failed to copy sqlprotect.so to staging directory"
	ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/share/" || _die "Failed to copy sqlprotect.sql to staging directory"
	ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/README-sqlprotect.txt $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64/doc/" || _die "Failed to copy README-sqlprotect.txt to staging directory"
    chmod -R ugo+r $WD/sqlprotect/staging/linux-x64

    cp $WD/sqlprotect/resources/licence.txt $WD/sqlprotect/staging/linux-x64/sqlprotect_license.txt || _die "Unable to copy sqlprotect_license.txt"
    chmod 444 $WD/sqlprotect/staging/linux-x64/sqlprotect_license.txt || _die "Unable to change permissions for license file"
    
    # Generate debug symbols
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64|| _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux-x64/sqlprotect ];
    then
        echo "Removing existing $WD/output/symbols/linux-x64/sqlprotect directory"
        rm -rf $WD/output/symbols/linux-x64/sqlprotect  || _die "Couldn't remove the existing $WD/output/symbols/linux-x64/sqlprotect directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux-x64 || _die "Failed to create $WD/output/symbols/linux-x64 directory"
    mv $WD/sqlprotect/staging/linux-x64/symbols $WD/output/symbols/linux-x64/sqlprotect || _die "Failed to move $WD/sqlprotect/staging/linux-x64/symbols to $WD/output/symbols/linux-x64/sqlprotect directory"

    echo "END BUILD sqlprotect Linux-x64"
}


################################################################################
# Post process
################################################################################

_postprocess_sqlprotect_linux_x64() {
    
    echo "BEGIN POST sqlprotect Linux-x64"

    cd $WD/sqlprotect
    
    # Set permissions to all files and folders in staging
    _set_permissions linux-x64
    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    cd $WD
    
    echo "END POST sqlprotect Linux-x64"
}
