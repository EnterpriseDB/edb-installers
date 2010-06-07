#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_sqlprotect_windows() {

    cd $WD/server/source
	
    # Remove any existing sqlprotect directory that might exist, in server
    if [ -e postgres.windows/contrib/SQLPROTECT ];
    then
      echo "Removing existing sqlprotect directory"
      rm -rf postgres.windows/contrib/SQLPROTECT || _die "Couldn't remove the existing sqlprotect directory"
    fi
	
    # create a copy of the sqlprotect tree
	cd postgres.windows/contrib
    git clone ssh://pginstaller@cvs.enterprisedb.com/git/SQLPROTECT
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/sqlprotect/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/sqlprotect/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/sqlprotect/staging/windows)"
    mkdir -p $WD/sqlprotect/staging/windows/sqlprotect || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/sqlprotect/staging/windows || _die "Couldn't set the permissions on the staging directory"
	
    echo "Archiving sqlprotect sources"
	cd $WD/server/source
    if [ -e sqlprotect.zip ];
    then
      echo "Removing existing source archive"
      rm sqlprotect.zip || _die "Couldn't remove sqlprotect.zip"
    fi
    zip sqlprotect.zip postgres.windows/contrib/SQLPROTECT/* || _die "Couldn't create archive of the sqlprotect sources (sqlprotect.zip)"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST sqlprotect.zip del /S /Q sqlprotect.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\sqlprotect.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST sqlprotect.staging rd /S /Q sqlprotect.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\sqlprotect.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST sqlprotect-staging.zip del /S /Q sqlprotect-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\sqlprotect-staging.zip on Windows VM"

    # Removing sqlprotect if it already exists
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/contrib; cmd /c if EXIST SQLPROTECT del /S /Q SQLPROTECT" || _die "Couldn't remove sqlprotect on windows VM (sqlprotect)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/release; cmd /c if EXIST sqlprotect del /S /Q sqlprotect" || _die "Couldn't remove sqlprotect on windows VM (sqlprotect)"

    # Copy sources on windows VM
    echo "Copying sqlprotect sources to Windows VM"
    scp sqlprotect.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the sqlprotect archive to windows VM (sqlprotect.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c  unzip sqlprotect.zip" || _die "Couldn't extract postgresql archieve on windows VM (sqlprotect.zip)"
    chmod -R ugo+r $WD/sqlprotect/staging/windows
 
}

################################################################################
# PG Build
################################################################################

_build_sqlprotect_windows() {

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/src/tools/msvc; ./build.bat sqlprotect RELEASE" || _die "could not build sqlprotect on windows vm"

   # We need to copy shared objects to staging directory
   ssh $PG_SSH_WINDOWS "mkdir -p $PG_PATH_WINDOWS/sqlprotect.staging/lib/postgresql" || _die "Failed to create the lib directory"
   ssh $PG_SSH_WINDOWS "mkdir -p $PG_PATH_WINDOWS/sqlprotect.staging/share" || _die "Failed to create the share directory"
   ssh $PG_SSH_WINDOWS "mkdir -p $PG_PATH_WINDOWS/sqlprotect.staging/doc" || _die "Failed to create the doc directory"
   
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/postgres.windows/release/sqlprotect/sqlprotect.dll $PG_PATH_WINDOWS/sqlprotect.staging/lib/postgresql" || _die "Failed to copy sqlprotect.dll to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/postgres.windows/contrib/SQLPROTECT/sqlprotect.sql $PG_PATH_WINDOWS/sqlprotect.staging/share" || _die "Failed to copy sqlprotect.sql to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/postgres.windows/contrib/SQLPROTECT/README-sqlprotect.txt $PG_PATH_WINDOWS/sqlprotect.staging/doc" || _die "Failed to copy README-sqlprotect.txt to staging directory"
   
   # Zip up the installed code, copy it back here, and unpack.
   echo "Copying sqlprotect build tree to Unix host"
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\sqlprotect.staging; cmd /c zip -r ..\\\\sqlprotect-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/sqlprotect.staging)"
   scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/sqlprotect-staging.zip $WD/sqlprotect/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/sqlprotect-staging.zip)"
   unzip $WD/sqlprotect/staging/windows/sqlprotect-staging.zip -d $WD/sqlprotect/staging/windows || _die "Failed to unpack the built source tree ($WD/staging/windows/sqlprotect-staging.zip)"
   rm $WD/sqlprotect/staging/windows/sqlprotect-staging.zip

}



################################################################################
# PG Build
################################################################################

_postprocess_sqlprotect_windows() {


    cd $WD/sqlprotect

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "sqlprotect-$PG_VERSION_SQLPROTECT-$PG_BUILDNUM_SQLPROTECT-windows.exe"
	
    cd $WD

}

