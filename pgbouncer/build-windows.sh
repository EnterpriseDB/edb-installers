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

    echo "Creating source directory ($WD/pgbouncer/source/pgbouncer.windows)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.windows || _die "Couldn't create the pgbouncer.windows directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q pgbouncer.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q pgbouncer-staging.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q build-pgbouncer.bat"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q pgbouncer.windows"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q pgbouncer.staging"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.windows || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    cd pgbouncer.windows
    patch -p0 < $WD/tarballs/pgbouncer_windows.patch
    cd $WD/pgbouncer/source 
    chmod -R ugo+w pgbouncer.windows || _die "Couldn't set the permissions on the source directory"

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

    echo "Creating staging doc directory ($WD/pgbouncer/staging/windows/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/windows/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod ugo+w $WD/pgbouncer/staging/windows/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/windows/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
    unix2dos $WD/pgbouncer/staging/windows/pgbouncer/doc/README-pgbouncer.txt|| _die "Failed to convert pgbouncer readme in dos readable format."

    echo "Copying pgbouncer sources to Windows VM"
    scp pgbouncer.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the pgbouncer archieve to windows VM (pgbouncer.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip pgbouncer.zip" || _die "Couldn't extract pgbouncer archieve on windows VM (pgbouncer.zip)"
}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_windows() {

    PG_PGBUILD_MINGW_WINDOWS=`echo $PG_PGBUILD_WINDOWS | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g'`

    cat <<EOT > "build-pgbouncer.bat"

@SET PATH=%PATH%;$PG_MINGW_WINDOWS\bin;$PG_MSYS_WINDOWS\bin;$PG_PGBUILD_WINDOWS\flex\bin;$PG_PGBUILD_WINDOWS\bison\bin;$PG_PGBUILD_WINDOWS\regex\bin

REM Configuring, building the pgbouncer source tree
@echo cd $PG_PATH_WINDOWS;export COMMONDIR=\$PWD; cd pgbouncer.windows; CPPFLAGS="-I$PG_PGBUILD_MINGW_WINDOWS/regex/include" LDFLAGS="-L$PG_PGBUILD_MINGW_WINDOWS/regex/lib" ./configure --prefix=\$COMMONDIR/pgbouncer.staging --with-libevent=$PG_PGBUILD_MINGW_WINDOWS/libevent-ppas; make; make install  | $PG_MSYS_WINDOWS\bin\sh --login -i

EOT

    scp build-pgbouncer.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the scripts source tree to the windows build host (scripts.zip)"
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c build-pgbouncer.bat " || _die "Failed to build pgbouncer on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\regex\\\\bin\\\\regex2.dll $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\bin" || _die "Failed to build pgbouncer on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\share\\\\doc\\\\pgbouncer\\\\pgbouncer.ini $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\share" || _die "Failed to copy  pgbouncer ini to share dir"

    # Copy psql and dependent libraries
    # Requirement : server component should be build before this component 
    mkdir -p $WD/pgbouncer/staging/windows/instscripts || _die "Failed to create the instscripts directory"

    # Copy the various support files into place
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to create the pgbouncer.staging\\\\instscripts directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\output\\\\bin\\\\psql.exe  $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy the psql.exe to the pgbouncer.staging\\\\instscripts directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\output\\\\bin\\\\libpq.dll  $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy the psql.exe to the pgbouncer.staging\\\\instscripts directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\vcredist\\\\vcredist_x86.exe $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy the VC++ runtimes on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\openssl\\\\bin\\\\ssleay32.dll $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\openssl\\\\bin\\\\libeay32.dll $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\iconv\\\\bin\\\\iconv.dll $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\gettext\\\\bin\\\\libintl-8.dll $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\gettext\\\\bin\\\\libiconv-2.dll $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\libxml2\\\\bin\\\\libxml2.dll $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\libxslt\\\\bin\\\\libxslt.dll $PG_PATH_WINDOWS\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\zlib\\\\zlib1.dll $PG_PATH_WINDOWS\\\\pgbouncer.staging\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows build host"
    

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

    PGBOUNCER_SERVICE_VER=`echo $PG_MAJOR_VERSION | sed 's/\.//'`
    
    mkdir -p staging/windows/installer/pgbouncer || _die "Failed to create directory for installer scripts"
    cp -R scripts/windows/check-connection.bat staging/windows/installer/pgbouncer/ || _die "Failed to copy the installer script"
    cp -R scripts/windows/startupcfg.bat staging/windows/installer/pgbouncer/ || _die "Failed to copy the installer script"
    cp -R scripts/windows/securefile.vbs staging/windows/installer/pgbouncer/ || _die "Failed to copy the installer script"

    rm -rf staging/windows/share/doc || _die "Failed to remove the extra doc directory"

    _replace ";foodb =" "@@CON@@" staging/windows/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = /var/log/pgbouncer/pgbouncer.log" "logfile = @@LOGFILE@@" staging/windows/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "pidfile = /var/run/pgbouncer/pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/windows/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/windows/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/windows/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_file = /etc/pgbouncer/userlist.txt" "auth_file = @@AUTHFILE@@" staging/windows/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/windows/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/windows/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_type = trust" "auth_type = md5" staging/windows/share/pgbouncer.ini || _die "Failed to change the auth type"  
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/windows/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"
    cp staging/windows/share/pgbouncer.ini staging/windows/share/pgbouncer.ini.org
    awk '{if($0=="\[pgbouncer\]"){print $0;print "service_name=pgbouncer-'$PGBOUNCER_SERVICE_VER'"}else{print $0}}' staging/windows/share/pgbouncer.ini.org >staging/windows/share/pgbouncer.ini || _die "Failed to change service name in pgbouncer.ini"

    rm -f staging/windows/share/pgbouncer.ini.org

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

	# Sign the installer
	win32_sign "pgbouncer-$PG_MAJOR_VERSION-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-windows.exe"
	
    cd $WD
}

