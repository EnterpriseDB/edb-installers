#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.windows ];
    then
      echo "Removing existing pgbouncer.windows source directory"
      rm -rf pgbouncer.windows  || _die "Couldn't remove the existing pgbouncer.windows source directory (source/pgbouncer.windows)"
      rm -f pgbouncer.zip  || _die "Couldn't remove the existing pgbouncer.zip file (source/pgbouncer.file)"
    fi

    if [ -e libevent.windows ];
    then
      echo "Removing existing libevent.windows source directory"
      rm -rf libevent.windows  || _die "Couldn't remove the existing libevent.windows source directory (source/libevent.windows)"
      rm -f libevent.zip  || _die "Couldn't remove the existing libevent.zip file (source/libevent.zip)"
    fi

    echo "Creating source directory ($WD/pgbouncer/source/libevent.windows)"
    mkdir -p $WD/pgbouncer/source/libevent.windows || _die "Couldn't create the libevent.windows directory"

    echo "Creating source directory ($WD/pgbouncer/source/pgbouncer.windows)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.windows || _die "Couldn't create the pgbouncer.windows directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q pgbouncer.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q libevent.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q build-pgbouncer.bat"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q build-libevent.bat"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q libevent.windows"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q pgbouncer.windows"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q libevent.staging"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q pgbouncer.staging"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.windows || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    chmod -R ugo+w pgbouncer.windows || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the source tree
    cp -R libevent-$PG_TARBALL_LIBEVENT/* libevent.windows || _die "Failed to copy the source code (source/libevent-$PG_TARBALL_LIBEVENT)"
    chmod -R ugo+w libevent.windows || _die "Couldn't set the permissions on the source directory"

    zip -r libevent.zip libevent.windows || _die "Failed to zip the libevent source" 
    zip -r pgbouncer.zip pgbouncer.windows || _die "Failed to zip the pgbouncer source" 


    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/windows)"
    mkdir -p $WD/pgbouncer/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/windows || _die "Couldn't set the permissions on the staging directory"

    echo "Copying pgbouncer sources to Windows VM"
    scp pgbouncer.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the pgbouncer archieve to windows VM (pgbouncer.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip pgbouncer.zip" || _die "Couldn't extract pgbouncer archieve on windows VM (pgbouncer.zip)"
    
    echo "Copying libevent sources to Windows VM"
    scp libevent.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the libevent archieve to windows VM (libevent.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip libevent.zip" || _die "Couldn't extract libevent archieve on windows VM (libevent.zip)"
}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_windows() {

    cat <<EOT > "build-libevent.bat"

@SET PATH=$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;C:\Perl\bin;C:\Python25;C:\Tcl\bin;

REM Configuring, building the libevent source tree
@echo cd $PG_PATH_WINDOWS;export COMMONDIR=\$PWD;cd libevent.windows;./configure --prefix=\$COMMONDIR/libevent.staging; make; make install  | $PG_MSYS_WINDOWS\bin\sh --login -i

EOT

    cat <<EOT > "build-pgbouncer.bat"

@SET PATH=$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;C:\Perl\bin;C:\Python25;C:\Tcl\bin;C:\regex-2.7\bin

REM Configuring, building the pgbouncer source tree
@echo cd $PG_PATH_WINDOWS;export COMMONDIR=\$PWD; cd pgbouncer.windows; CPPFLAGS="-I/c/regex-2.7/include" LDFLAGS="-L/c/regex-2.7/lib" ./configure --prefix=\$COMMONDIR/pgbouncer.staging --with-libevent=\$COMMONDIR/libevent.staging; make; make install  | $PG_MSYS_WINDOWS\bin\sh --login -i

EOT

    scp build-pgbouncer.bat build-libevent.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the scripts source tree to the windows build host (scripts.zip)"
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-libevent.bat " || _die "Failed to build libevent on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-pgbouncer.bat " || _die "Failed to build pgbouncer on the windows build host"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying pgbouncer built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\pgbouncer.staging; cmd /c zip -r ..\\\\pgbouncer-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/pgbouncer.staging)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/pgbouncer-staging.zip $WD/pgbouncer/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/pgbouncer-staging.zip)"
    unzip $WD/pgbouncer/staging/windows/pgbouncer-staging.zip -d $WD/pgbouncer/staging/windows || _die "Failed to unpack the built source tree ($WD/staging/windows/pgbouncer-staging.zip)"
    rm $WD/pgbouncer/staging/windows/pgbouncer-staging.zip

}

################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_windows() {
 

    cd $WD/pgbouncer

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    cd $WD
}

