#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_metainstaller_windows() {

    # Enter the staging directory and cleanup if required
   
    if [ -e $WD/MetaInstaller/staging/windows ];
    then
      echo "Removing existing windows staging directory"
      rm -rf $WD/MetaInstaller/staging/windows  || _die "Couldn't remove the existing windows staging directory (staging/windows)"
    fi

    echo "Creating staging directory ($WD/MetaInstaller/staging/windows)"
    mkdir -p $WD/MetaInstaller/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/MetaInstaller/staging/windows || _die "Couldn't set the permissions on the staging directory"

    mkdir -p  $WD/MetaInstaller/staging/windows/scripts || _die "Couldn't create the staging/windows/script directory"
    chmod ugo+w $WD/MetaInstaller/staging/windows/scripts || _die "Couldn't set the permissions on the staging/windows/script directory"

    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
       
    # Grab a copy of the postgresql installer
    cp -R "$WD/output/postgresql-$PG_PACKAGE_VERSION-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the postgresql installer (staging/windows/postgresql-$PG_PACKAGE_VERSION-windows.exe)"
    # Grab a copy of the slony installer
    cp -R "$WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the slony installer (staging/windows/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-windows.exe)"
    # Grab a copy of the pgjdbc installer
    cp -R "$WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the pgjdbc installer (staging/windows/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-windows.exe)"
    # Grab a copy of the psqlodbc installer
    cp -R "$WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the psqlodbc installer (staging/windows/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-windows.exe)"
    # Grab a copy of the postgis installer
    cp -R "$WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the postgis installer (staging/windows/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-windows.exe)"
    # Grab a copy of the npgsql installer
    cp -R "$WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the postgis installer (staging/windows/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-windows.exe)"




    # Grab a copy of the pgbouncer installer
    cp -R "$WD/output/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the pgbouncer installer (staging/windows/pgbouncer-$PG_VERSION_PGBOUNCER-$PG_BUILDNUM_PGBOUNCER-windows.exe"

    # Grab a copy of the pgmemcache installer
   # cp -R "$WD/output/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the pgmemcache installer (staging/windows/pgmemcache-pg$PG_CURRENT_VERSION-$PG_VERSION_PGMEMCACHE-$PG_BUILDNUM_PGMEMCACHE-windows.exe"

    # Grab a copy of the pgagent installer
    cp -R "$WD/output/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-windows.exe"  $WD/MetaInstaller/staging/windows || _die "Failed to copy the pgagent installer (staging/windows/pgagent-$PG_VERSION_PGAGENT-$PG_BUILDNUM_PGAGENT-windows.exe"



    # Cleanup the build host
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q meta_output_scripts"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q windowsComponents"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q metawinComponents.zip"
    #ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q metavc-build.bat"	

	# Cleanup local files
    if [ -f $WD/MetaInstaller/scripts/metavc-build.bat ];
    then
        echo "Removing existing metavc-build script"
        rm -rf $WD/MetaInstaller/scripts/metavc-build.bat || _die "Couldn't remove the existing metavc-build script"
    fi

    cd $WD/MetaInstaller/staging/windows/scripts

    mkdir pgcontrol

    #Copy pgcontrol.exe from server's staging
    if [ ! -f $WD/server/staging/windows/bin/pg_controldata.exe ];
    then
      _die "$WD/server/staging/windows/bin/pg_controldata.exe does not exist. Please run server module first."
    fi
    cd $WD/server/staging/windows/bin
    cp -R pg_controldata.exe  $WD/MetaInstaller/staging/windows/scripts/pgcontrol || _die "Failed to copy the pg_controldata.exe  (MetaInstaller/staging/windows/scripts/pgcontrol)"
    cp -R libiconv-2.dll  $WD/MetaInstaller/staging/windows/scripts/pgcontrol || _die "Failed to copy the libiconv-2.dll  (MetaInstaller/staging/windows/scripts/pgcontrol)"
    cp -R libintl-8.dll  $WD/MetaInstaller/staging/windows/scripts/pgcontrol || _die "Failed to copy the libintl-8.dll  (MetaInstaller/staging/windows/scripts/pgcontrol)"


    cd $WD/server/staging/windows/installer
    cp -R vcredist_x86.exe  $WD/MetaInstaller/staging/windows/scripts || _die "Failed to copy the vcredist_x86.exe  (MetaInstaller/staging/windows/scripts)"


    cd $WD/PostGIS/scripts/windows
    cp -R check-connection.bat  $WD/MetaInstaller/staging/windows/scripts || _die "Failed to copy the check-connection.bat  (MetaInstaller/staging/windows/scripts)"

    cp -R check-db.bat  $WD/MetaInstaller/staging/windows/scripts || _die "Failed to copy the check-db.bat  (MetaInstaller/staging/windows/scripts)"
   
    cd $WD/server/staging/windows/installer/server
    cp -R getlocales.exe  $WD/MetaInstaller/staging/windows/scripts || _die "Failed to copy the getlocales.exe  (MetaInstaller/staging/windows/scripts)"

   cp -R validateuser.exe  $WD/MetaInstaller/staging/windows/scripts || _die "Failed to copy the validateuser.exe  (MetaInstaller/staging/windows/scripts)"

   cp -R createuser.exe  $WD/MetaInstaller/staging/windows/scripts || _die "Failed to copy the createuser.exe  (MetaInstaller/staging/windows/scripts)"


    cd $WD/server/scripts/windows
    cp -R installruntimes.vbs  $WD/MetaInstaller/staging/windows/scripts || _die "Failed to copy the installruntimes.vbs  (MetaInstaller/staging/windows/scripts)"

    cp -R $WD/MetaInstaller/scripts/windows/*.bat  $WD/MetaInstaller/staging/windows/scripts/ || _die "Failed to copy the scripts"
    
        
}

################################################################################
# Build
################################################################################

_build_metainstaller_windows() {


   # Create a build script for VC++
   cd $WD/MetaInstaller/scripts
	
   cat <<EOT > "metavc-build.bat"
@SET VSINSTALLDIR=C:\Program Files\Microsoft Visual Studio 8
@SET VCINSTALLDIR=C:\Program Files\Microsoft Visual Studio 8\VC
@SET FrameworkDir=C:\WINDOWS\Microsoft.NET\Framework
@SET FrameworkVersion=v2.0.50727
@SET FrameworkSDKDir=C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0

@set DevEnvDir=C:\Program Files\Microsoft Visual Studio 8\Common7\IDE

@set PATH=C:\Program Files\Microsoft Visual Studio 8\Common7\IDE;C:\Program Files\Microsoft Visual Studio 8\VC\BIN;C:\Program Files\Microsoft Visual Studio 8\Common7\Tools;C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\bin;C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK\bin;C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0\bin;C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727;C:\Program Files\Microsoft Visual Studio 8\VC\VCPackages;%PATH%
@set INCLUDE=C:\Program Files\Microsoft Visual Studio 8\VC\ATLMFC\INCLUDE;C:\Program Files\Microsoft Visual Studio 8\VC\INCLUDE;C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK\include;C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0\include;%INCLUDE%
@set LIB=C:\Program Files\Microsoft Visual Studio 8\VC\ATLMFC\LIB;C:\Program Files\Microsoft Visual Studio 8\VC\LIB;C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK\lib;C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0\lib;%LIB%
@set LIBPATH=C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727;C:\Program Files\Microsoft Visual Studio 8\VC\ATLMFC\LIB

vcbuild %1 %2 %3 %4 %5 %6 %7 %8 %9
EOT
    
    # Zip up the scripts directories and copy them to the build host, then unzip
    cd $WD/MetaInstaller/scripts
    echo "Copying windows components source tree to Windows build VM"
    zip -r metawinComponents.zip metavc-build.bat windows || _die "Failed to pack the windows components source tree (ms-build.bat metavc-build.bat, metawindowsComponents)"

    # Make directory for meta installer's windows components

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; mkdir windowsComponents" || _die "Failed to make directory windowsComponents"

    scp metawinComponents.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS\\\\windowsComponents || _die "Failed to copy the windows  components source tree to the windows build host (metawinComponents.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\windowsComponents; cmd /c unzip metawinComponents.zip" || _die "Failed to unpack the windows components source tree on the windows build host (metawinComponents.zip)"	
	
    # Build the code and install into a temporary directory

    #ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/createuser; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat createuser.vcproj" || _die "Failed to build createuser on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/dbserver_guid/dbserver_guid/dbserver_guid; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat dbserver_guid.vcproj" || _die "Failed to build dbserver_guid on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/features/features; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat features.vcproj" || _die "Failed to build features on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/getDynaTune; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat getDynaTune.vcproj" || _die "Failed to build getDynaTune on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/isUserValidated; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat isUserValidated.vcproj" || _die "Failed to build isUserValidated on the windows build host"
  
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/modifyPostgresql/modifyPostgresql; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat modifyPostgresql.vcproj" || _die "Failed to build modifyPostgresql on the windows build host"

    #ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/validateosuser/validateuser; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat validateuser.vcproj" || _die "Failed to build validateosuser on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/validateUser; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat validateUser.vcproj" || _die "Failed to build validateUser on the windows build host"

    #ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/windows/getlocales; cmd /c $PG_PATH_WINDOWS\\\\windowsComponents\\\\metavc-build.bat getlocales.vcproj" || _die "Failed to build getlocales on the windows build host"

	
    # Move the resulting binaries into place
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to create the windows directory on the windows build host"

	#ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\createuser\\\\Release\\\\createuser.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the createuser proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\dbserver_guid\\\\dbserver_guid\\\\dbserver_guid\\\\Release\\\\dbserver_guid.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the dbserver_guid proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\features\\\\features\\\\Release\\\\features.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the features proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\getDynaTune\\\\Release\\\\getDynaTune.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the getDynaTune proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\isUserValidated\\\\Release\\\\isUserValidated.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the isUserValidated proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\modifyPostgresql\\\\modifyPostgresql\\\\Release\\\\modifyPostgresql.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the modifyPostgresql proglet on the windows build host" 

	#ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\validateosuser\\\\validateuser\\\\Release\\\\validateuser.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the validateuser proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\validateUser\\\\Release\\\\validateUserClient.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the validateUserClient proglet on the windows build host" 

	#ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\windows\\\\getlocales\\\\Release\\\\getlocales.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the getlocales proglet on the windows build host"

    
    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows; cmd /c zip -r metaoutput.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/meta_output_scripts)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/meta_output_scripts/scripts/windows/metaoutput.zip $WD/MetaInstaller/staging/windows/scripts || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/meta_output_scripts/scripts/windows/metaoutput.zip)"
    unzip $WD/MetaInstaller/staging/windows/scripts/metaoutput.zip -d $WD/MetaInstaller/staging/windows/scripts || _die "Failed to unpack the built source tree ($WD/MetaInstaller/resources/scripts/windows/output.zip)"
    rm $WD/MetaInstaller/staging/windows/scripts/metaoutput.zip

    rm $WD/MetaInstaller/scripts/metawinComponents.zip
    rm $WD/MetaInstaller/scripts/metavc-build.bat
	   
    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_metainstaller_windows() {

    cd  $WD/MetaInstaller

    
    # Build the installer

    "$PG_INSTALLBUILDER_BIN" build postgresplus.xml windows || _die "Failed to build the installer"
    # Rename the installer
    mv $WD/output/postgresplus-$PG_MAJOR_VERSION-windows-installer.exe $WD/output/postgresplus-$PG_PACKAGE_VERSION-windows.exe || _die "Failed to rename the installer"    


    cd $WD
	    
}

