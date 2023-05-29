#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pgbouncer_windows_x64() {

    echo "BEGIN PREP pgbouncer Windows-x64"    

    # Enter the source directory and cleanup if required
    cd $WD/pgbouncer/source

    if [ -e pgbouncer.windows-x64 ];
    then
      echo "Removing existing pgbouncer.windows-x64 source directory"
      rm -rf pgbouncer.windows-x64  || _die "Couldn't remove the existing pgbouncer.windows-x64 source directory (source/pgbouncer.windows-x64)"
      rm -f pgbouncer.zip  || _die "Couldn't remove the existing pgbouncer.zip file (source/pgbouncer.file)"
    fi

    if [ -e libevent.windows-x64 ];
    then
      echo "Removing existing libevent.windows-x64 source directory"
      rm -rf libevent.windows-x64  || _die "Couldn't remove the existing libevent.windows-x64 source directory (source/libevent.windows-x64)"
      rm -f libevent.zip  || _die "Couldn't remove the existing libevent.zip file (source/libevent.zip)"
    fi

    echo "Creating source directory ($WD/pgbouncer/source/pgbouncer.windows-x64)"
    mkdir -p $WD/pgbouncer/source/pgbouncer.windows-x64 || _die "Couldn't create the pgbouncer.windows-x64 directory"

    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q pgbouncer.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q pgbouncer-staging.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q build-pgbouncer.bat"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q pgbouncer.windows-x64"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q pgbouncer.staging.build"

    # Grab a copy of the source tree
    cp -R pgbouncer-$PG_VERSION_PGBOUNCER/* pgbouncer.windows-x64 || _die "Failed to copy the source code (source/pgbouncer-$PG_VERSION_PGBOUNCER)"
    cd $WD/pgbouncer/source 

    zip -r pgbouncer.zip pgbouncer.windows-x64 || _die "Failed to zip the pgbouncer source" 

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pgbouncer/staging/windows-x64)"
    mkdir -p $WD/pgbouncer/staging/windows-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"

    echo "Creating staging doc directory ($WD/pgbouncer/staging/windows-x64/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/windows-x64/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $WD/pgbouncer/staging/windows-x64/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/windows-x64/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
    unix2dos $WD/pgbouncer/staging/windows-x64/pgbouncer/doc/README-pgbouncer.txt|| _die "Failed to convert pgbouncer readme in dos readable format."

    echo "Copying pgbouncer sources to Windows-x64 VM"
    scp pgbouncer.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Couldn't copy the pgbouncer archieve to windows-x64 VM (pgbouncer.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip pgbouncer.zip" || _die "Couldn't extract pgbouncer archieve on windows-x64 VM (pgbouncer.zip)"

    echo "END PREP pgbouncer Windows-x64"
}

################################################################################
# PG Build
################################################################################

_build_pgbouncer_windows_x64() {

    echo "BEGIN BUILD pgbouncer Windows-x64"

    PG_PGBUILD_MINGW_WINDOWS_X64=`echo $PG_PGBUILD_WINDOWS_X64 | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g'`
    PG_MINGW_WINDOWS_X64_PGBOUNCER_INSTALLED=`echo $PG_MINGW_WINDOWS_X64_PGBOUNCER | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g'`
   # PG_BUILD_PGBOUNCER_OPENSSL=`echo $PG_PGBUILD_OPENSSL_WINDOWS_X64 | sed -e 's/://g' -e 's:\\\\:/:g' -e 's:^:/:g'`
    cat <<EOT > "build-pgbouncer.bat"

@SET PATH=$PATH:$PG_MINGW_WINDOWS_X64_PGBOUNCER_INSTALLED//bin:$PG_MSYS_WINDOWS_X64_PGBOUNCER//bin:$PG_PGBUILD_MINGW_WINDOWS_X64//bin
@SET TEMP=/tmp

REM Configuring, building the pgbouncer source tree
@echo cd $PG_PATH_WINDOWS_X64;export COMMONDIR=\$PWD; cd pgbouncer.windows-x64; CPPFLAGS="-I$PG_PGBUILD_MINGW_WINDOWS_X64//include" LDFLAGS="-L$PG_PGBUILD_MINGW_WINDOWS_X64//lib" PATH=$PG_MINGW_WINDOWS_X64_PGBOUNCER_INSTALLED//bin:\$PATH LIBEVENT_LIBS="-L$PG_PGBUILD_MINGW_WINDOWS_X64/lib -levent" LIBEVENT_CFLAGS="-I$PG_PGBUILD_MINGW_WINDOWS_X64/include" ./configure --host=x86_64-w64-mingw32 --build=x86_64-w64-mingw32 --target=x86_64-w64-mingw32 -with-cares=no --prefix=\$COMMONDIR/pgbouncer.staging.build  --with-openssl=$PG_PGBUILD_MINGW_WINDOWS_X64; PATH=$PG_MINGW_WINDOWS_X64_PGBOUNCER_INSTALLED//bin:\$PATH make; make install  | $PG_MSYS_WINDOWS_X64_PGBOUNCER\bin\sh --login -i

EOT

    scp build-pgbouncer.bat $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the scripts source tree to the windows-x64 build host (scripts.zip)"
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c build-pgbouncer.bat " || _die "Failed to build pgbouncer on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\regex2.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\bin" || _die "Failed to build pgbouncer on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libevent*.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\bin" || _die "Failed to build pgbouncer on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libssl-3-x64.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\bin" || _die "Failed to build pgbouncer on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libcrypto-3-x64.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\bin" || _die "Failed to build pgbouncer on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_GETTEXT_WINDOWS_X64\\\\bin\\\\libwinpthread-1.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\bin" || _die "Failed to copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libwinpthread-1.dll into $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\bin"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\mingw-binaries\\\\libgcc_s_seh-1.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\bin" || _die "Failed to copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libgcc_s_dw2-1.dll into $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\bin"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\share\\\\doc\\\\pgbouncer\\\\pgbouncer.ini $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\share" || _die "Failed to copy  pgbouncer ini to share dir"

    # Copy psql and dependent libraries
    # Requirement : server component should be build before this component 
    mkdir -p $WD/pgbouncer/staging/windows-x64/instscripts || _die "Failed to create the instscripts directory"

    # Copy the various support files into place
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to create the pgbouncer.staging.build\\\\instscripts directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\output\\\\bin\\\\psql.exe  $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy the psql.exe to the pgbouncer.staging.build\\\\instscripts directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\output\\\\bin\\\\libpq.dll  $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy the psql.exe to the pgbouncer.staging.build\\\\instscripts directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\vcredist\\\\vcredist_x64.exe $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy the VC++ runtimes on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libssl-3-x64.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libcrypto-3-x64.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libiconv-2.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_GETTEXT_WINDOWS_X64\\\\bin\\\\libintl-9.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libxml2.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libxslt.dll $PG_PATH_WINDOWS_X64\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\zlib1.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_GETTEXT_WINDOWS_X64\\\\bin\\\\libwinpthread-1.dll $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging.build\\\\instscripts" || _die "Failed to copy a dependency DLL on the windows-x64 build host"    

    echo "Removing last successful staging directory ($PG_PATH_WINDOWS_X64\\\\pgbouncer.staging)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST pgbouncer.staging rd /S /Q pgbouncer.staging" || _die "Couldn't remove the last successful staging directory directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging" || _die "Couldn't create the last successful staging directory"

    echo "Copying the complete build to the successful staging directory"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c xcopy /E /Q /Y pgbouncer.staging.build\\\\* pgbouncer.staging\\\\" || _die "Couldn't copy the existing staging directory"

    ssh $PG_SSH_WINDOWS_X64 "cmd /c echo PG_VERSION_PGBOUNCER=$PG_VERSION_PGBOUNCER > $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging/versions-windows-x64.sh" || _die "Failed to write pgbouncer version number into versions-windows-x64.sh"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c echo PG_BUILDNUM_PGBOUNCER=$PG_BUILDNUM_PGBOUNCER >> $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging/versions-windows-x64.sh" || _die "Failed to write pgbouncer build number into versions-windows-x64.sh"


    echo "END BUILD pgbouncer Windows-x64"
}

################################################################################
# PG Build
################################################################################

_postprocess_pgbouncer_windows_x64() {
 
    echo "BEGIN POST pgbouncer Windows-x64"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pgbouncer/staging/windows-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pgbouncer/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi
    echo "Creating staging directory ($WD/pgbouncer/staging/windows-x64)"
    mkdir -p $WD/pgbouncer/staging/windows-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pgbouncer/staging/windows-x64 || _die "Couldn't set the permissions on the staging directory"

    echo "Creating staging doc directory ($WD/pgbouncer/staging/windows-x64/pgbouncer/doc)"
    mkdir -p $WD/pgbouncer/staging/windows-x64/pgbouncer/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $WD/pgbouncer/staging/windows-x64/pgbouncer/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying README.pgbouncer to staging doc directory"
    cp $WD/pgbouncer/resources/README.pgbouncer $WD/pgbouncer/staging/windows-x64/pgbouncer/doc/README-pgbouncer.txt || _die "Couldn't copy README.pgbouncer to staging doc directory"
    unix2dos $WD/pgbouncer/staging/windows-x64/pgbouncer/doc/README-pgbouncer.txt|| _die "Failed to convert pgbouncer readme in dos readable format."

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying pgbouncer built tree to Unix host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c if EXIST pgbouncer-staging.zip del /S /Q pgbouncer-staging.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS_X64\pgbouncer-staging.zip on Windows-x64 VM"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\pgbouncer.staging; cmd /c zip -r ..\\\\pgbouncer-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/pgbouncer.staging)"
    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/pgbouncer-staging.zip $WD/pgbouncer/staging/windows-x64 || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/pgbouncer-staging.zip)"
    unzip $WD/pgbouncer/staging/windows-x64/pgbouncer-staging.zip -d $WD/pgbouncer/staging/windows-x64 || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/pgbouncer-staging.zip)"
    rm $WD/pgbouncer/staging/windows-x64/pgbouncer-staging.zip

    dos2unix $WD/pgbouncer/staging/windows-x64/versions-windows-x64.sh || _die "Failed to convert format of versions-windows-x64.sh from dos to unix"
    source $WD/pgbouncer/staging/windows-x64/versions-windows-x64.sh
    PG_BUILD_PGBOUNCER=$(expr $PG_BUILD_PGBOUNCER + $SKIPBUILD)

    cd $WD/pgbouncer

    pushd staging/windows-x64
    generate_3rd_party_license "pgbouncer"
    popd

    mkdir -p staging/windows-x64/installer/pgbouncer || _die "Failed to create directory for installer scripts"
    cp -R scripts/windows/check-connection.bat staging/windows-x64/installer/pgbouncer/ || _die "Failed to copy the installer script"
    cp -R scripts/windows/startupcfg.bat staging/windows-x64/installer/pgbouncer/ || _die "Failed to copy the installer script"
    cp -R scripts/windows/securefile.vbs staging/windows-x64/installer/pgbouncer/ || _die "Failed to copy the installer script"

    rm -rf staging/windows-x64/share/doc || _die "Failed to remove the extra doc directory"

    _replace ";foodb =" "@@CON@@" staging/windows-x64/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "logfile = /var/log/pgbouncer/pgbouncer.log" "logfile = @@LOGFILE@@" staging/windows-x64/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "pidfile = /var/run/pgbouncer/pgbouncer.pid" "pidfile = @@PIDFILE@@" staging/windows-x64/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_addr = 127.0.0.1" "listen_addr = *" staging/windows-x64/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "listen_port = 6432" "listen_port = @@LISTENPORT@@" staging/windows-x64/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_file = /etc/pgbouncer/userlist.txt" "auth_file = @@AUTHFILE@@" staging/windows-x64/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";admin_users = user2, someadmin, otheradmin" "admin_users = @@ADMINUSERS@@" staging/windows-x64/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace ";stats_users = stats, root" "stats_users = @@STATSUSERS@@" staging/windows-x64/share/pgbouncer.ini || _die "Failed to put the place holder"
    _replace "auth_type = trust" "auth_type = md5" staging/windows-x64/share/pgbouncer.ini || _die "Failed to change the auth type"  
    _replace ";ignore_startup_parameters = extra_float_digits" "ignore_startup_parameters = application_name" staging/windows-x64/share/pgbouncer.ini || _die "Failed to uncomment the ignore startup parameters config line"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows-x64 || _die "Failed to build the installer"

   # If build passed empty this variable
   BUILD_FAILED="build_failed-"
   if [ $PG_BUILD_PGBOUNCER -gt 0 ];
   then
       BUILD_FAILED=""
   fi

    # Rename the installer
    mv $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-windows-x64.exe $WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}windows-x64.exe

	# Sign the installer
	win32_sign "pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-${BUILD_FAILED}windows-x64.exe"
	
    cd $WD

    echo "END POST pgbouncer Windows-x64"
}
