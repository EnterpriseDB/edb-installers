#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Slony_windows() {
      
    # Enter the source directory and cleanup if required
    cd $WD/Slony/source


    if [ ! -e postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows ]; 
    then 
         echo "Creating postgresql_mingw source directory ($WD/Slony/source/postgresql_mingw.windows)"
         mkdir -p postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Couldn't create the postgresql_mingw.windows directory"
         chmod ugo+w postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Couldn't set the permissions on the source directory"
         cp -R postgresql-$PG_TARBALL_POSTGRESQL/* postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows || _die "Failed to copy the source code (source/postgresql-$PG_MAJOR_VERSION.$PG_MINOR_VERSION/)"
         if [ ! -e postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip ];
         then
                zip -r postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows/ || _die "Couldn't create archieve of the postgresql_mingw sources (postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"
         fi
    fi   

    if [ -e Slony.windows ];
    then
      echo "Removing existing Slony.windows source directory"
      rm -rf Slony.windows  || _die "Couldn't remove the existing Slony.windows source directory (source/Slony.windows)"
    fi

    echo "Creating Slony source directory ($WD/Slony/source/Slony.windows)"
    mkdir -p Slony.windows || _die "Couldn't create the Slony.windows directory"
    chmod ugo+w Slony.windows || _die "Couldn't set the permissions on the source directory"
    # Grab a copy of the Slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* Slony.windows || _die "Failed to copy the source code (source/Slony-$PG_VERSION_Slony)"
    echo "Archieving Slony sources"
    zip -r Slony.zip Slony.windows/ || _die "Couldn't create archieve of the Slony sources (Slony.zip)"
    chmod -R ugo+w Slony.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/windows)"
    mkdir -p $WD/Slony/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/windows || _die "Couldn't set the permissions on the staging directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Slony.zip del /S /Q Slony.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Slony.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip del /S /Q postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Slony.windows rd /S /Q Slony.windows" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Slony.windows directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST Slony.staging rd /S /Q Slony.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\Slony.staging directory on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-Slony.bat del /S /Q build-Slony.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-Slony.bat on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST build-postgresql_mingw.bat del /S /Q build-postgresql_mingw.bat" || _die "Couldn't remove the $PG_PATH_WINDOWS\\build-postgresql_mingw.bat on Windows VM"

    # Copy sources on windows VM
    echo "Copying postgresql sources to Windows VM"
    scp postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the postgresql archieve to windows VM (postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if NOT EXIST postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows unzip postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip" || _die "Couldn't extract postgresql archieve on windows VM (postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.zip)"

    echo "Copying Slony sources to Windows VM"
    scp Slony.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the Slony archieve to windows VM (Slony.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip Slony.zip" || _die "Couldn't extract Slony archieve on windows VM (Slony.zip)"

    PG_PGHOME_WINDOWS=$PG_PATH_WINDOWS/pgsql

    echo "Removing existing slony files from the PostgreSQL directory"
    ssh $PG_SSH_WINDOWS "cd $PG_PGHOME_WINDOWS; rm -f bin/slon.exe bin/slonik.exe lib/slony_funcs.dll lib/xxid.dll lib/slevent.dll"  || _die "Failed to remove slony binary files"
    ssh $PG_SSH_WINDOWS "cd $PG_PGHOME_WINDOWS; rm -f share/slony*.sql && rm -f share/xxid*.sql"  || _die "remove slony share files"


        
}


################################################################################
# PG Build
################################################################################

_build_Slony_windows() {

    # build Slony    
    PG_STAGING=`echo $PG_PATH_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    PG_PGHOME_WINDOWS=$PG_PATH_WINDOWS/pgsql 
    PG_PGHOME_MINGW_WINDOWS=$PG_STAGING/pgsql 
    PG_PATH_MINGW_WINDOWS=`echo $PG_MINGW_WINDOWS | sed -e 's/://g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/:g'`
    PG_PGBUILD_MINGW_WINDOWS=`echo $PG_PGBUILD_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g'`


    cat <<EOT > "build-postgresql_mingw.bat"

@ECHO OFF

@SET PATH=$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;C:\Perl\bin;C:\Python25;C:\Tcl\bin

@ECHO cd $PG_PATH_WINDOWS\\\\postgresql_mingw-$PG_MAJOR_VERSION.$PG_MINOR_VERSION.windows; ./configure --prefix=$PG_PGHOME_MINGW_WINDOWS --with-libs=$PG_PGBUILD_MINGW_WINDOWS/krb5/lib/i386:$PG_PGBUILD_MINGW_WINDOWS/OpenSSL/lib; make; make install | $PG_MSYS_WINDOWS\bin\sh --login -i


EOT

    scp build-postgresql_mingw.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c IF NOT EXIST pgsql build-postgresql_mingw.bat" 

    cat <<EOT > "build-Slony.bat"

@SET PATH=$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;C:\Perl\bin;C:\Python25;C:\Tcl\bin

REM Configuring, building the Slony source tree
@echo cd $PG_PATH_WINDOWS/Slony.windows; ./configure --with-pgconfigdir=$PG_PGHOME_MINGW_WINDOWS/bin; make; make install  | $PG_MSYS_WINDOWS\bin\sh --login -i

EOT

   scp build-Slony.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-Slony.bat" 
    
   # Slony installs it's files into postgresql directory
   # We need to copy them to staging directory
   ssh $PG_SSH_WINDOWS  "mkdir -p $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PGHOME_WINDOWS/bin/slon.exe $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to copy slon binary to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PGHOME_WINDOWS/bin/slonik.exe $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to copy slonik binary to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_MINGW_WINDOWS/lib/pthreadGC2.dll $PG_PATH_WINDOWS/Slony.staging/bin" || _die "Failed to copy slonik binary to staging directory"

   ssh $PG_SSH_WINDOWS "mkdir -p $PG_PATH_WINDOWS/Slony.staging/lib" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PGHOME_WINDOWS/lib/slony1_funcs.dll $PG_PATH_WINDOWS/Slony.staging/lib" || _die "Failed to copy slony_funcs.dll to staging directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PGHOME_WINDOWS/lib/slevent.dll $PG_PATH_WINDOWS/Slony.staging/lib" || _die "Failed to copy slevent.dll to staging directory"

   ssh $PG_SSH_WINDOWS "mkdir -p $PG_PATH_WINDOWS/Slony.staging/Slony" || _die "Failed to create the bin directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PGHOME_WINDOWS/share/slony*.sql $PG_PATH_WINDOWS/Slony.staging/Slony" || _die "Failed to share files to staging directory"

   # Zip up the installed code, copy it back here, and unpack.
   echo "Copying slony built tree to Unix host"
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\Slony.staging; cmd /c zip -r ..\\\\slony-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/Slony.staging)"
   scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/slony-staging.zip $WD/Slony/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/slony-staging.zip)"
   unzip $WD/Slony/staging/windows/slony-staging.zip -d $WD/Slony/staging/windows || _die "Failed to unpack the built source tree ($WD/staging/windows/slony-staging.zip)"
   rm $WD/Slony/staging/windows/slony-staging.zip
}
    


################################################################################
# PG Build
################################################################################

_postprocess_Slony_windows() {

    cd $WD/Slony

    mkdir -p staging/windows/installer/Slony || _die "Failed to create a directory for the install scripts"

    cp scripts/windows/configureslony.bat staging/windows/installer/Slony/configureslony.bat || _die "Failed to copy the configureSlony script (scripts/windows/configureslony.bat)"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"


    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
    
    cd $WD
}

