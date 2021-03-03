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
    git clone git://github.ox.uk.enterprisedb.com/edb-sql-protect SQLPROTECT
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/linux-x64.build ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/linux-x64.build || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/sqlprotect/staging/linux-x64.build)"
    mkdir -p $WD/sqlprotect/staging/linux-x64.build/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/linux-x64.build || _die "Couldn't set the permissions on the staging directory"
   
    echo "END PREP sqlprotect Linux-x64"	
}

################################################################################
# Build
################################################################################

_build_sqlprotect_linux_x64() {

    PG_STAGING=$PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64.build

    echo "BEGIN BUILD sqlprotect Linux-x64"

    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/; make distclean ; make" || _die "Failed to build sqlprotect"
	
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64.build/lib/postgresql" || _die "Failed to create staging/linux-x64.build/lib/postgresql"
	ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64.build/share" || _die "Failed to create staging/linux-x64.build/share"
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64.build/doc" || _die "Failed to create staging/linux-x64.build/doc"

    ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/sqlprotect.so $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64.build/lib/postgresql/" || _die "Failed to copy sqlprotect.so to staging directory"
	ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64.build/share/" || _die "Failed to copy sqlprotect.sql to staging directory"
	ssh $PG_SSH_LINUX_X64 "cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/contrib/SQLPROTECT/README-sqlprotect.txt $PG_PATH_LINUX_X64/sqlprotect/staging/linux-x64.build/doc/" || _die "Failed to copy README-sqlprotect.txt to staging directory"
    chmod -R ugo+r $WD/sqlprotect/staging/linux-x64.build

    cp $WD/sqlprotect/resources/licence.txt $WD/sqlprotect/staging/linux-x64.build/sqlprotect_license.txt || _die "Unable to copy sqlprotect_license.txt"
    chmod 444 $WD/sqlprotect/staging/linux-x64.build/sqlprotect_license.txt || _die "Unable to change permissions for license file"
    
    # Generate debug symbols
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/resources; chmod 755 create_debug_symbols.sh; ./create_debug_symbols.sh $PG_STAGING" || _die "Failed to execute create_debug_symbols.sh"

    # Remove existing symbols directory in output directory
    if [ -e $WD/output/symbols/linux-x64/sqlprotect ];
    then
        echo "Removing existing $WD/output/symbols/linux-x64/sqlprotect directory"
        rm -rf $WD/output/symbols/linux-x64/sqlprotect  || _die "Couldn't remove the existing $WD/output/symbols/linux-x64/sqlprotect directory."
    fi

    # Move symbols directory in output
    mkdir -p $WD/output/symbols/linux-x64 || _die "Failed to create $WD/output/symbols/linux-x64 directory"
    mv $WD/sqlprotect/staging/linux-x64.build/symbols $WD/output/symbols/linux-x64/sqlprotect || _die "Failed to move $WD/sqlprotect/staging/linux-x64.build/symbols to $WD/output/symbols/linux-x64/sqlprotect directory"

    echo "Removing last successful staging directory ($WD/sqlprotect/staging/linux-x64)"
    rm -rf $WD/sqlprotect/staging/linux-x64 || _die "Couldn't remove the last successful staging directory"
    mkdir -p $WD/sqlprotect/staging/linux-x64 || _die "Couldn't create the last successful staging directory"
    chmod ugo+w $WD/sqlprotect/staging/linux-x64 || _die "Couldn't set the permissions on the successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    cp -rp $WD/sqlprotect/staging/linux-x64.build/* $WD/sqlprotect/staging/linux-x64 || _die "Couldn't copy the existing staging directory"
    echo "PG_VERSION_SQLPROTECT=$PG_VERSION_SQLPROTECT" > $WD/sqlprotect/staging/linux-x64/versions-linux-x64.sh
    echo "PG_BUILDNUM_SQLPROTECT=$PG_BUILDNUM_SQLPROTECT" >> $WD/sqlprotect/staging/linux-x64/versions-linux-x64.sh

    echo "END BUILD sqlprotect Linux-x64"
}


################################################################################
# Post process
################################################################################

_postprocess_sqlprotect_linux_x64() {
    
    echo "BEGIN POST sqlprotect Linux-x64"

    source $WD/sqlprotect/staging/linux-x64/versions-linux-x64.sh
    PG_BUILD_SQLPROTECT=$(expr $PG_BUILD_SQLPROTECT + $SKIPBUILD)

    _registration_plus_postprocess "$WD/sqlprotect/staging"  "SQL Protect" "sqlprotectVersion" "/etc/postgres-reg.ini" "sqlprotect-PG_$PG_MAJOR_VERSION" "sqlprotect-PG_$PG_MAJOR_VERSION" "SQL Protect" "$PG_VERSION_SQLPROTECT"

    cd $WD/sqlprotect
    
    # Set permissions to all files and folders in staging
    _set_permissions linux-x64
    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"

    # If build passed empty this variable
    BUILD_FAILED="build_failed-"
    if [ $PG_BUILD_SQLPROTECT -gt 0 ];
    then
        BUILD_FAILED=""
    fi

    # Rename the installer
    mv $WD/output/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-linux-x64.run $WD/output/edb-sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-${BUILD_FAILED}linux-x64.run

    cd $WD
    
    echo "END POST sqlprotect Linux-x64"
}
