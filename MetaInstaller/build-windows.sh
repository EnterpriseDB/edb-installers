#!/bin/bash
    
################################################################################
# Build preparation
################################################################################

_prep_metainstaller_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/MetaInstaller/installers
    if [ -e windows ];
    then
        echo "Removing existing windows source directory"
        rm -rf windows  || _die "Couldn't remove the existing windows source directory (installers/windows)"
    fi
    
    mkdir windows

    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
       
    # Grab a copy of the postgresql installer
    cp -R "$WD/output/postgresql-$PG_PACKAGE_VERSION-windows.exe"  $WD/MetaInstaller/installers/windows || _die "Failed to copy the postgresql installer (installers/windows/postgresql-$PG_PACKAGE_VERSION-windows.exe)"
    # Grab a copy of the slony installer
    cp -R "$WD/output/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-windows.exe"  $WD/MetaInstaller/installers/windows || _die "Failed to copy the slony installer (installers/windows/slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-windows.exe)"
    # Grab a copy of the pgjdbc installer
    cp -R "$WD/output/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-windows.exe"  $WD/MetaInstaller/installers/windows || _die "Failed to copy the pgjdbc installer (installers/windows/pgjdbc-$PG_VERSION_PGJDBC-$PG_BUILDNUM_PGJDBC-windows.exe)"
    # Grab a copy of the psqlodbc installer
    cp -R "$WD/output/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-windows.exe"  $WD/MetaInstaller/installers/windows || _die "Failed to copy the psqlodbc installer (installers/windows/psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-windows.exe)"
    # Grab a copy of the postgis installer
    cp -R "$WD/output/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-windows.exe"  $WD/MetaInstaller/installers/windows || _die "Failed to copy the postgis installer (installers/windows/postgis-pg$PG_CURRENT_VERSION-$PG_VERSION_POSTGIS-$PG_BUILDNUM_POSTGIS-windows.exe)"

    cp -R "$WD/output/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-windows.exe"  $WD/MetaInstaller/installers/windows || _die "Failed to copy the postgis installer (installers/windows/npgsql-$PG_VERSION_NPGSQL-$PG_BUILDNUM_NPGSQL-windows.exe)"

    cd $WD/MetaInstaller/resources/scripts/windows

    rm -rf *.exe
    rm -rf pgcontrol

    rm -rf check-connection.bat
    rm -rf check-db.bat
    rm -rf installruntimes.vbs
        
    # Cleanup the build host
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q meta_output_scripts"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q windowsComponents"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q metawinComponents.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q metavc-build.bat"	

	# Cleanup local files
    if [ -f $WD/MetaInstaller/resources/metavc-build.bat ];
    then
        echo "Removing existing vc-build script"
        rm -rf $WD/MetaInstaller/resources/metavc-build.bat || _die "Couldn't remove the existing vc-build script"
    fi
    
        
}

################################################################################
# Build
################################################################################

_build_metainstaller_windows() {


    cd $WD/MetaInstaller/resources/scripts/windows

    mkdir pgcontrol

    #Copy pgcontrol.exe from server's staging
    if [ ! -f $WD/server/staging/windows/bin/pg_controldata.exe ];
    then
      _die "$WD/server/staging/windows/bin/pg_controldata.exe does not exist. Please run server module first."
    fi
    cd $WD/server/staging/windows/bin
    cp -R pg_controldata.exe  $WD/MetaInstaller/resources/scripts/windows/pgcontrol || _die "Failed to copy the pg_controldata.exe  (MetaInstaller/resources/scripts/windows/pgcontrol)"
    cp -R libiconv-2.dll  $WD/MetaInstaller/resources/scripts/windows/pgcontrol || _die "Failed to copy the libiconv-2.dll  (MetaInstaller/resources/scripts/windows/pgcontrol)"
    cp -R libintl-8.dll  $WD/MetaInstaller/resources/scripts/windows/pgcontrol || _die "Failed to copy the libintl-8.dll  (MetaInstaller/resources/scripts/windows/pgcontrol)"


    cd $WD/server/staging/windows/installer
    cp -R vcredist_x86.exe  $WD/MetaInstaller/resources/scripts/windows || _die "Failed to copy the vcredist_x86.exe  (MetaInstaller/resources/scripts/windows)"


    cd $WD/PostGIS/scripts/windows
    cp -R check-connection.bat  $WD/MetaInstaller/resources/scripts/windows || _die "Failed to copy the check-connection.bat  (MetaInstaller/resources/scripts/windows)"

    cp -R check-db.bat  $WD/MetaInstaller/resources/scripts/windows || _die "Failed to copy the check-db.bat  (MetaInstaller/resources/scripts/windows)"
   
    cd $WD/server/staging/windows/installer/server
    cp -R getlocales.exe  $WD/MetaInstaller/resources/scripts/windows || _die "Failed to copy the getlocales.exe  (MetaInstaller/resources/scripts/windows)"

   cp -R validateuser.exe  $WD/MetaInstaller/resources/scripts/windows || _die "Failed to copy the validateuser.exe  (MetaInstaller/resources/scripts/windows)"

   cp -R createuser.exe  $WD/MetaInstaller/resources/scripts/windows || _die "Failed to copy the createuser.exe  (MetaInstaller/resources/scripts/windows)"


    cd $WD/server/scripts/windows
    cp -R installruntimes.vbs  $WD/MetaInstaller/resources/scripts/windows || _die "Failed to copy the installruntimes.vbs  (MetaInstaller/resources/scripts/windows)"
	
	# Create a build script for VC++
	cd $WD/MetaInstaller/resources
	
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


@SET PGDIR=$PG_PATH_WINDOWS\scripts\windows

vcbuild %1 %2 %3 %4 %5 %6 %7 %8 %9
EOT
    
    # Zip up the scripts directories and copy them to the build host, then unzip
    cd $WD/MetaInstaller/resources
    echo "Copying windowsComponents source tree to Windows build VM"
    zip -r metawinComponents.zip metavc-build.bat windowsComponents || _die "Failed to pack the windowsComponents source tree (ms-build.bat metavc-build.bat, metawindowsComponents)"

    scp metawinComponents.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the windowsComponents source tree to the windows build host (winComponents.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip metawinComponents.zip" || _die "Failed to unpack the windowsComponents source tree on the windows build host (metawinComponents.zip)"	
	
    # Build the code and install into a temporary directory

    #ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/createuser; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat createuser.vcproj" || _die "Failed to build createuser on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/dbserver_guid/dbserver_guid/dbserver_guid; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat dbserver_guid.vcproj" || _die "Failed to build dbserver_guid on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/features/features; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat features.vcproj" || _die "Failed to build features on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/getDynaTune; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat getDynaTune.vcproj" || _die "Failed to build getDynaTune on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/isUserValidated; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat isUserValidated.vcproj" || _die "Failed to build isUserValidated on the windows build host"
  
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/modifyPostgresql/modifyPostgresql; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat modifyPostgresql.vcproj" || _die "Failed to build modifyPostgresql on the windows build host"

    #ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/validateosuser/validateuser; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat validateuser.vcproj" || _die "Failed to build validateosuser on the windows build host"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/validateUser; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat validateUser.vcproj" || _die "Failed to build validateUser on the windows build host"

    #ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/windowsComponents/getlocales; cmd /c $PG_PATH_WINDOWS\\\\metavc-build.bat getlocales.vcproj" || _die "Failed to build getlocales on the windows build host"

	
    # Move the resulting binaries into place
	ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to create the windows directory on the windows build host"

	#ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\createuser\\\\Release\\\\createuser.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the createuser proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\dbserver_guid\\\\dbserver_guid\\\\dbserver_guid\\\\Release\\\\dbserver_guid.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the dbserver_guid proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\features\\\\features\\\\Release\\\\features.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the features proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\getDynaTune\\\\Release\\\\getDynaTune.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the getDynaTune proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\isUserValidated\\\\Release\\\\isUserValidated.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the isUserValidated proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\modifyPostgresql\\\\modifyPostgresql\\\\Release\\\\modifyPostgresql.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the modifyPostgresql proglet on the windows build host" 

	#ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\validateosuser\\\\validateuser\\\\Release\\\\validateuser.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the validateuser proglet on the windows build host" 

	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\validateUser\\\\Release\\\\validateUserClient.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the validateUserClient proglet on the windows build host" 

	#ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\windowsComponents\\\\getlocales\\\\Release\\\\getlocales.exe $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows" || _die "Failed to copy the getlocales proglet on the windows build host"

    
    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\meta_output_scripts\\\\scripts\\\\windows; cmd /c zip -r metaoutput.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/meta_output_scripts)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/meta_output_scripts/scripts/windows/metaoutput.zip $WD/MetaInstaller/resources/scripts/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/meta_output_scripts/scripts/windows/metaoutput.zip)"
    unzip $WD/MetaInstaller/resources/scripts/windows/metaoutput.zip -d $WD/MetaInstaller/resources/scripts/windows || _die "Failed to unpack the built source tree ($WD/MetaInstaller/resources/scripts/windows/output.zip)"
    rm $WD/MetaInstaller/resources/scripts/windows/metaoutput.zip
	   
    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_metainstaller_windows() {

    cd  $WD/MetaInstaller

    
    # Build the installer

    "$PG_INSTALLBUILDER_BIN" build postgresplus.xml windows || _die "Failed to build the installer"
    
    cd $WD
	    
}

