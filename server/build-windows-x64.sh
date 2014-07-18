#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_server_windows_x64() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP Server Windows-x64"

    # Enter the source directory and cleanup if required
    cd $WD/server/source
    
    if [ -e postgres.windows-x64 ];
    then
        echo "Removing existing postgres.windows-x64 source directory"
        rm -rf postgres.windows-x64  || _die "Couldn't remove the existing postgres.windows-x64 source directory (source/postgres.windows-x64)"
    fi
    if [ -e pgadmin.windows-x64 ];
    then
        echo "Removing existing pgadmin.windows-x64 source directory"
        rm -rf pgadmin.windows-x64  || _die "Couldn't remove the existing pgadmin.windows-x64 source directory (source/pgadmin.windows-x64)"
    fi
    if [ -e stackbuilder.windows-x64 ];
    then
        echo "Removing existing stackbuilder.windows-x64 source directory"
        rm -rf stackbuilder.windows-x64  || _die "Couldn't remove the existing stackbuilder.windows-x64 source directory (source/stackbuilder.windows-x64)"
    fi
    
    # Remove any existing zip files
    if [ -f $WD/server/source/postgres-win64.zip ];
    then
        echo "Removing existing source archive"
        rm -rf $WD/server/source/postgres-win64.zip || _die "Couldn't remove the existing source archive"
    fi
    if [ -f $WD/server/source/pgadmin-win64.zip ];
    then
        echo "Removing existing pgadmin archive"
        rm -rf $WD/server/source/pgadmin-win64.zip || _die "Couldn't remove the existing pgadmin archive"
    fi
    if [ -f $WD/server/source/stackbuilder-win64.zip ];
    then
        echo "Removing existing stackbuilder archive"
        rm -rf $WD/server/source/stackbuilder-win64.zip || _die "Couldn't remove the existing stackbuilder archive"
    fi
    if [ -f $WD/server/scripts/windows/scripts.zip ];
    then
        echo "Removing existing scripts archive"
        rm -rf $WD/server/scripts/windows/scripts.zip || _die "Couldn't remove the existing scripts archive"
    fi
    if [ -f $WD/server/staging/windows-x64/output.zip ];
    then
        echo "Removing existing output archive"
        rm -rf $WD/server/staging/windows-x64/output.zip || _die "Couldn't remove the existing output archive"
    fi
    
    # Cleanup the build host
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q postgres-win64.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q pgadmin-win64.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q stackbuilder-win64.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q scripts.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q output.zip"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q vc-build-x64.bat"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q vc-build.bat"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q output"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q postgres.windows-x64"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q pgadmin.windows-x64"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q stackbuilder.windows-x64"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q createuser"    
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q getlocales"    
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c rd /S /Q validateuser"
    
    # Cleanup local files
    if [ -f $WD/server/scripts/windows/vc-build.bat ];
    then
        echo "Removing existing vc-build script"
        rm -rf $WD/server/scripts/windows/vc-build.bat || _die "Couldn't remove the existing vc-build script"
    fi

    if [ -f $WD/server/scripts/windows/vc-build-x64.bat ];
    then
        echo "Removing existing vc-build-x64 script"
        rm -rf $WD/server/scripts/windows/vc-build-x64.bat || _die "Couldn't remove the existing vc-build-x64 script"
    fi

    
    # Grab a copy of the source tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL postgres.windows-x64 || _die "Failed to copy the source code (source/postgres.windows-x64)"

    cp -R pgadmin3-$PG_TARBALL_PGADMIN pgadmin.windows-x64 || _die "Failed to copy the source code (source/pgadmin.windows-x64)"
    cp -R stackbuilder stackbuilder.windows-x64 || _die "Failed to copy the source code (source/stackbuilder.windows-x64)"
    
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/windows-x64 ];
    then
        echo "Removing existing staging directory"
        rm -rf $WD/server/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/windows-x64)"
    mkdir -p $WD/server/staging/windows-x64 || _die "Couldn't create the staging directory"

    echo "END PREP Server Windows-x64"
}

################################################################################
# Build
################################################################################

_build_server_windows_x64() {
    echo "BEGIN BUILD Server Windows-x64"
    
    # Create a build script for VC++
    cd $WD/server/scripts/windows
    cat <<EOT > "vc-build.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS_X64\VC\vcvarsall.bat" x86

@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET OPENSSL=$PG_PGBUILD_WINDOWS
@SET WXWIN=$PG_WXWIN_WINDOWS
@SET INCLUDE=$PG_PGBUILD_WINDOWS\\include;%INCLUDE%
@SET LIB=$PG_PGBUILD_WINDOWS\\lib;%LIB%
@SET PGDIR=$PG_PATH_WINDOWS\\output
@SET SPHINXBUILD=C:\\Python27-x86\\Scripts\\sphinx-build.exe

IF "%2" == "UPGRADE" GOTO upgrade

msbuild %1 /p:Configuration=%2 
GOTO end

:upgrade
devenv /upgrade %1

:end

EOT

  
    cat <<EOT > "vc-build-x64.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS_X64\VC\vcvarsall.bat" amd64

@SET PGBUILD=$PG_PGBUILD_WINDOWS_X64
@SET OPENSSL=$PG_PGBUILD_WINDOWS_X64
@SET WXWIN=$PG_WXWIN_WINDOWS_X64
@SET INCLUDE=$PG_PGBUILD_WINDOWS_X64\\include;%INCLUDE%
@SET LIB=$PG_PGBUILD_WINDOWS_X64\\lib;%LIB%
@SET PGDIR=$PG_PATH_WINDOWS_X64\\output
@SET SPHINXBUILD=C:\\Python27-x64\\Scripts\\sphinx-build.exe

IF "%2" == "UPGRADE" GOTO upgrade

msbuild %1 /p:Configuration=%2
GOTO end

:upgrade
devenv /upgrade %1

:end

EOT

 
    # Copy in an appropriate config.pl and buildenv.pl
    cd $WD/server/source/
    cat <<EOT > "postgres.windows-x64/src/tools/msvc/config.pl"
# Configuration arguments for vcbuild.
use strict;
use warnings;

our \$config = {
    asserts=>0,                         # --enable-cassert
    integer_datetimes=>1,               # --enable-integer-datetimes
    nls=>'$PG_PGBUILD_WINDOWS_X64',        # --enable-nls=<path>
    perl=>'$PG_PERL_WINDOWS_X64',             # --with-perl
    python=>'$PG_PYTHON_WINDOWS_X64',         # --with-python=<path>
    tcl=>'$PG_TCL_WINDOWS_X64',            # --with-tls=<path>
    ldap=>1,                # --with-ldap
    openssl=>'$PG_PGBUILD_WINDOWS_X64',     # --with-ssl=<path>
    xml=>'$PG_PGBUILD_WINDOWS_X64',
    xslt=>'$PG_PGBUILD_WINDOWS_X64',
    iconv=>'$PG_PGBUILD_WINDOWS_X64',
    zlib=>'$PG_PGBUILD_WINDOWS_X64',        # --with-zlib=<path>
    uuid=>'$PG_PGBUILD_WINDOWS_X64'       # --with-uuid-ossp
};

1;
EOT

    cat <<EOT > "postgres.windows-x64/src/tools/msvc/buildenv.pl"
use strict;
use warnings;

\$ENV{VSINSTALLDIR} = '$PG_VSINSTALLDIR_WINDOWS_X64';
\$ENV{VCINSTALLDIR} = '$PG_VSINSTALLDIR_WINDOWS_X64\VC';
\$ENV{VS90COMNTOOLS} = '$PG_VSINSTALLDIR_WINDOWS_X64\Common7\Tools';
\$ENV{FrameworkDir} = 'C:\WINDOWS\Microsoft.NET\Framework64';
\$ENV{FrameworkVersion} = '$PG_FRAMEWORKVERSION_WINDOWS_X64';
\$ENV{Framework35Version} = 'v3.5';
\$ENV{FrameworkSDKDir} = '$PG_FRAMEWORKSDKDIR_WINDOWS_X64';
\$ENV{DevEnvDir} = '$PG_DEVENVDIR_WINDOWS_X64';
\$ENV{M4} = '$PG_PGBUILD_WINDOWS_X64\bin\m4.exe';

\$ENV{PATH} = join
(
    ';' ,
    '$PG_DEVENVDIR_WINDOWS_X64',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\bin\amd64',
    '$PG_VSINSTALLDIR_WINDOWS_X64\Common7\Tools',
    '$PG_VSINSTALLDIR_WINDOWS_X64\Common7\Tools\bin',
    '$PG_FRAMEWORKSDKDIR_WINDOWS_X64\bin',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\PlatformSDK\Bin',
    'C:\WINDOWS\Microsoft.NET\Framework64\\$PG_FRAMEWORKVERSION_WINDOWS_X64',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\VCPackages',
    '$PG_PGBUILD_WINDOWS_X64\bin',
    '$PG_PERL_WINDOWS_X64\bin',
    '$PG_PYTHON_WINDOWS_X64',
    '$PG_TCL_WINDOWS_X64\bin',
    \$ENV{PATH}
);
         
\$ENV{INCLUDE} = join
(
    ';',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\ATLMFC\INCLUDE',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\INCLUDE',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\PlatformSDK\include',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\PlatformSDK\include',
    '$PG_FRAMEWORKSDKDIR_WINDOWS_X64\include',
    '$PG_PGBUILD_WINDOWS_X64\include',
    \$ENV{INCLUDE}
);

\$ENV{LIB} = join
(
    ';',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\ATLMFC\LIB',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\LIB',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\PlatformSDK\lib',
    '$PG_FRAMEWORKSDKDIR_WINDOWS_X64\lib',
    '$PG_PGBUILD_WINDOWS_X64\lib',
    \$ENV{LIB}
);

\$ENV{LIBPATH} = join
(
    ';',
    'C:\Windows\Microsoft.NET\Framework64\\$PG_FRAMEWORKVERSION_WINDOWS_X64',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\ATLMFC\LIB'
);

1;
EOT

    # Create a config file for the debugger
    cat <<EOT > "postgres.windows-x64/contrib/pldebugger/settings.projinc"
<?xml version="1.0"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" DefaultTargets="all">

    <PropertyGroup>
    
        <!-- Debug build? -->
        <DEBUG>0</DEBUG>

        <!-- Compiler Architecture -->
        <ARCH>x64</ARCH>

        <!-- PostgreSQL source tree -->
        <PGPATH>..\..\</PGPATH>
        
        <!-- Gettext source tree -->
        <GETTEXTPATH>$PG_PGBUILD_WINDOWS_X64</GETTEXTPATH>
        
        <!-- OpenSSL source tree -->
        <OPENSSLPATH>$PG_PGBUILD_WINDOWS_X64</OPENSSLPATH>
        
    </PropertyGroup>
</Project>
EOT

        
    # Zip up the scripts directories and copy them to the build host, then unzip
    cd $WD/server/scripts/windows/
    echo "Copying scripts source tree to Windows build VM"
    zip -r scripts.zip vc-build.bat vc-build-x64.bat createuser getlocales validateuser || _die "Failed to pack the scripts source tree (ms-build.bat vc-build-x64.bat vc-build-x64.bat, createuser, getlocales, validateuser)"

    scp -v scripts.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the scripts source tree to the windows-x64 build host (scripts.zip)"
    ssh -v $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; unzip scripts.zip" || _die "Failed to unpack the scripts source tree on the windows-x64 build host (scripts.zip)"    
    
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\createuser; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat createuser.vcproj UPGRADE" || _die "Failed to build createuser on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\createuser; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat createuser.vcxproj Release" || _die "Failed to build createuser on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\getlocales; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat getlocales.vcproj UPGRADE" || _die "Failed to build getlocales on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\getlocales; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat getlocales.vcxproj Release" || _die "Failed to build getlocales on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\validateuser; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat validateuser.vcproj UPGRADE" || _die "Failed to build validateuser on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\validateuser; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat validateuser.vcxproj Release" || _die "Failed to build validateuser on the windows-x64 build host"
    
    # Move the resulting binaries into place
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\output\\\\installer\\\\server" || _die "Failed to create the server directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\createuser\\\\x64\\\\release\\\\createuser.exe $PG_PATH_WINDOWS_X64\\\\output\\\\installer\\\\server" || _die "Failed to copy the createuser proglet on the windows-x64 build host" 
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\getlocales\\\\x64\\\\release\\\\getlocales.exe $PG_PATH_WINDOWS_X64\\\\output\\\\installer\\\\server" || _die "Failed to copy the getlocales proglet on the windows-x64 build host" 
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\validateuser\\\\x64\\\\release\\\\validateuser.exe $PG_PATH_WINDOWS_X64\\\\output\\\\installer\\\\server" || _die "Failed to copy the validateuser proglet on the windows-x64 build host" 
    
    # Zip up the source directory and copy it to the build host, then unzip
    cd $WD/server/source/
    echo "Copying source tree to Windows build VM"
    rm postgres.windows-x64/contrib/pldebugger/Makefile # Remove the unix makefile so that the build scripts don't try to parse it - we have our own.
    zip -r postgres-win64.zip postgres.windows-x64 || _die "Failed to pack the source tree (postgres.windows-x64)"
    scp -v postgres-win64.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the source tree to the windows-x64 build host (postgres-win64.zip)"
    ssh -v $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip postgres-win64.zip" || _die "Failed to unpack the source tree on the windows-x64 build host (postgres-win64.zip)"
  
    PG_CYGWIN_PERL_WINDOWS_X64=`echo $PG_PERL_WINDOWS_X64 | sed -e 's;:;;g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/cygdrive/:g'`
    PG_CYGWIN_PYTHON_WINDOWS_X64=`echo $PG_PYTHON_WINDOWS_X64 | sed -e 's;:;;g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/cygdrive/:g'`    
    PG_CYGWIN_TCL_WINDOWS_X64=`echo $PG_TCL_WINDOWS_X64 | sed -e 's;:;;g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/cygdrive/:g'`
    PG_CYGWIN_PGBUILD_WINDOWS_X64=`echo $PG_PGBUILD_WINDOWS_X64 | sed -e 's;:;;g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/cygdrive/:g'`

 
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/src/tools/msvc; export PATH=\$PATH:$PG_CYGWIN_PERL_WINDOWS_X64/bin:$PG_CYGWIN_PYTHON_WINDOWS_X64:$PG_CYGWIN_TCL_WINDOWS_X64/bin:$PG_CYGWIN_PGBUILD_WINDOWS_X64/bin; export M4=$PG_CYGWIN_PGBUILD_WINDOWS_X64/bin/m4.exe; ./build.bat RELEASE" || _die "Failed to build postgres on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/src/tools/msvc; export PATH=\$PATH:$PG_CYGWIN_PERL_WINDOWS_X64/bin:$PG_CYGWIN_PYTHON_WINDOWS_X64:$PG_CYGWIN_TCL_WINDOWS_X64/bin; ./install.bat $PG_PATH_WINDOWS_X64\\\\output" || _die "Failed to install postgres on the windows-x64 build host"
    
    # Build the debugger plugins
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/contrib/pldebugger; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat pldebugger.proj" || _die "Failed to build the pldebugger plugin"
    
    # Copy the debugger plugins into place
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\contrib\\\\pldebugger\\\\plugin_debugger.dll $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy the debugger plugin on the windows-x64 build host"    
    
    #####################
    # pgAdmin
    #####################

    #cd pgadmin.windows-x64/pgadmin
    #_replace "\$(PGBUILD)/libxml2" "\$(PGBUILD)" pgAdmin3.vcproj || _die "Failed to replace the include directory"
    #_replace "\$(PGBUILD)/libxslt" "\$(PGBUILD)" pgAdmin3.vcproj || _die "Failed to replace the include directory"
    #_replace "\$(PGBUILD)/iconv" "\$(PGBUILD)" pgAdmin3.vcproj || _die "Failed to replace the include directory"
    #_replace "iconv_a.lib" " " pgAdmin3.vcproj || _die "Failed to replace the include directory"
    #cd ../..
 
    echo "Copying pgAdmin source tree to Windows build VM"
    zip -r pgadmin-win64.zip pgadmin.windows-x64 || _die "Failed to pack the source tree (pgadmin.windows-x64)"
    scp -v pgadmin-win64.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the source tree to the windows-x64 build host (pgadmin-win64.zip)"
    ssh -v $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip pgadmin-win64.zip" || _die "Failed to unpack the source tree on the windows-x64 build host (pgadmin-win64.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat pgAdmin3.sln UPGRADE" || _die "Failed to build pgAdmin on the build host"
 
    # Build the PNG compiler 
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/xtra/png2c; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat png2c.vcxproj Release" || _die "Failed to build png2c on the build host"

    # Precompile the PNG images. We need to do this for the build system, as it 
    # won't work over cygwin.
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/pgadmin/include/images; for F in *.png; do echo Compiling \${F}... && ../../../xtra/png2c/Release/png2c.exe \${F} \${F}c ; done"
 
    # Build the code
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/pgadmin; cmd /c ver_svn.bat"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/pgadmin; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat pgadmin3.vcxproj Release" || _die "Failed to build pgAdmin on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/docs; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build.bat Docs.vcxproj All" || _die "Failed to build the docs on the build host"
        
    # Copy the application files into place
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\"" || _die "Failed to create a directory on the windows-x64 build host" || _die "Failed to create the studio directory on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\pgadmin\\\\Release\\\\pgAdmin3.exe $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a program file on the windows-x64 build host"
    
    # Docs
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\en_US\\\\_build\\\\htmlhelp; cp -R *  \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\"" || _die "Failed to copy a help file on the windows-x64 build host"

    # There's no particularly clean way to do this as we don't want all the files, and each language may or may not be completely transated :-(
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\en_US\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"

    # i18n
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\i18n\\\\pg_settings.csv \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to copy an i18n file on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\i18n\\\\pgadmin3.lng \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to copy an i18n file on the windows-x64 build host"
    
    for LANGCODE in `grep "PUB_TX " $WD/server/source/pgadmin.windows-x64/i18n/Makefile.am | cut -d = -f2`
    do
       ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\i18n\\\\$LANGCODE\"" || _die "Failed to create a directory on the windows-x64 build host"
        ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\i18n\\\\$LANGCODE\\\\*.mo \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\i18n\\\\$LANGCODE\"" || _die "Failed to copy an i18n file on the windows-x64 build host"    
     ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\pgadmin\\\\*.ini \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\\"" || _die "Failed to copy ini files on the windows-x64 build host"    
    done
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\plugins.d\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy  $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\plugins.d\\\\*.ini \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\plugins.d\"" || _die "Failed to copy ini files on the windows-x64 build host"    
    
    #####################
    # StackBuilder
    #####################
    cd $WD/server/source/
    echo "Copying StackBuilder source tree to Windows build VM"
    zip -r stackbuilder-win64.zip stackbuilder.windows-x64 || _die "Failed to pack the source tree (stackbuilder.windows-x64)"
    scp -v stackbuilder-win64.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the source tree to the windows-x64 build host (stackbuilder-win64.zip)"
    ssh -v $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip stackbuilder-win64.zip" || _die "Failed to unpack the source tree on the windows-x64 build host (stackbuilder-win64.zip)"
  
    # Build the code
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/stackbuilder.windows-x64; cmd /c cmake -G \"Visual Studio 10 Win64\" -D MS_VS_10=1 -D WX_ROOT_DIR=$PG_WXWIN_WINDOWS_X64 -D MSGFMT_EXECUTABLE=$PG_PGBUILD_WINDOWS_X64\\\\bin\\\\msgfmt -D CMAKE_INSTALL_PREFIX=$PG_PATH_WINDOWS_X64\\\\output\\\\StackBuilder -D CMAKE_CXX_FLAGS=\"/D _UNICODE /EHsc\" ." || _die "Failed to configure stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/stackbuilder.windows-x64; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat stackbuilder.vcxproj Release" || _die "Failed to build stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/stackbuilder.windows-x64; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat INSTALL.vcxproj Release" || _die "Failed to install stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mv $PG_PATH_WINDOWS_X64\\\\output\\\\StackBuilder\\\\bin\\\\stackbuilder.exe $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to relocate the stackbuilder executable on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c rd $PG_PATH_WINDOWS_X64\\\\output\\\\StackBuilder\\\\bin" || _die "Failed to remove the stackbuilder bin directory on the build host"

    # Copy the various support files into place
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\vcredist\\\\vcredist_x64.exe $PG_PATH_WINDOWS_X64\\\\output\\\\installer" || _die "Failed to copy the VC++ runtimes on the windows build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\ssleay32.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libeay32.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\iconv.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libintl-8.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libxml2.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\libxslt.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\bin\\\\zlib1.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\ssleay32.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\libeay32.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\VC\\\\libeay32MD.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\VC\\\\ssleay32MD.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\iconv.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\intl.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\libxml2.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\libxslt.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\lib\\\\zlib.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host" 
    # Copy the third party headers 
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\include\\\\*.h $PG_PATH_WINDOWS_X64\\\\output\\\\include" || _die "Failed to copy third party headers on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\include\\\\openssl\"" || _die "Failed to create openssl directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\include\\\\openssl\\\\*.h $PG_PATH_WINDOWS_X64\\\\output\\\\include\\\\openssl" || _die "Failed to copy third party headers on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\include\\\\libxml\"" || _die "Failed to create libxml directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\include\\\\libxml\\\\*.h $PG_PATH_WINDOWS_X64\\\\output\\\\include\\\\libxml" || _die "Failed to copy third party headers on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\include\\\\libxslt\"" || _die "Failed to create libxslt directory"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PGBUILD_WINDOWS_X64\\\\include\\\\libxslt\\\\*.h $PG_PATH_WINDOWS_X64\\\\output\\\\include\\\\libxslt" || _die "Failed to copy third party headers on the windows-x64 build host"

    # Copy the wxWidgets libraries
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxbase28u_net_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxbase28u_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxbase28u_xml_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_adv_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_aui_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_core_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_html_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_stc_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_xrc_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxbase28u_net.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxbase28u.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxbase28u_xml.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_adv.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_aui.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_core.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_html.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_stc.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_WXWIN_WINDOWS_X64\\\\lib\\\\vc_dll\\\\wxmsw28u_xrc.lib $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows-x64 build host"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to Unix host"
    ssh -v $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\output; zip -r ..\\\\output.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output)"
    scp -v $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output.zip $WD/server/staging/windows-x64 || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output.zip)"
    unzip $WD/server/staging/windows-x64/output.zip -d $WD/server/staging/windows-x64/ || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/output.zip)"
    rm $WD/server/staging/windows-x64/output.zip

	win32_sign "stackbuilder.exe" "$WD/server/staging/windows-x64/bin"
    
    # Install the PostgreSQL docs
    mkdir -p $WD/server/staging/windows-x64/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $WD/server/staging/windows-x64/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -R $WD/server/source/postgres.windows-x64/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"
    
    # Copy in the plDebugger docs & SQL script
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/README.pldebugger $WD/server/staging/windows-x64/doc
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/pldbgapi*.sql $WD/server/staging/windows-x64/share/extension
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/pldbgapi.control $WD/server/staging/windows-x64/share/extension
     
    cd $WD
    echo "END BUILD Server Windows-x64"
}


################################################################################
# Post process
################################################################################

_postprocess_server_windows_x64() {
    echo "BEGIN POST Server Windows-x64"

    cd $WD/server

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/windows-x64/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.png" "$WD/server/staging/windows-x64/doc/" || _die "Failed to install the welcome logo"


    cp "$WD/scripts/runAsAdmin.vbs" "$WD/server/staging/windows-x64" || _die "Failed to copy the runAsRoot script"
    _replace @@SERVER_SUFFIX@@ "x64" $WD/server/staging/windows-x64/runAsAdmin.vbs || _die "Failed to replace the SERVER_SUFFIX setting in the runAsAdmin.vbs"

    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/windows-x64/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/windows-x64
    cp -R bin doc include lib pgAdmin* share StackBuilder symbols pgsql/ || _die "Failed to copy the binaries to the pgsql directory"

    zip -rq postgresql-$PG_PACKAGE_VERSION-windows-x64-binaries.zip pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-windows-x64-binaries.zip $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory" 

    cd $WD/server

    # Setup the installer scripts. 
    mkdir -p staging/windows-x64/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/prerun_checks.vbs staging/windows-x64/installer/prerun_checks.vbs || _die "Failed to copy the prerun_checks.vbs script ($WD/scripts/windows-x64/prerun_checks.vbs)"
    cp scripts/windows/initcluster.vbs staging/windows-x64/installer/server/initcluster.vbs || _die "Failed to copy the loadmodules script (scripts/windows/initcluster.vbs)"
    cp scripts/windows/startupcfg.vbs staging/windows-x64/installer/server/startupcfg.vbs || _die "Failed to copy the startupcfg script (scripts/windows/startupcfg.vbs)"
    cp scripts/windows/createshortcuts.vbs staging/windows-x64/installer/server/createshortcuts.vbs || _die "Failed to copy the createshortcuts script (scripts/windows/createshortcuts.vbs)"
    cp scripts/windows/startserver.vbs staging/windows-x64/installer/server/startserver.vbs || _die "Failed to copy the startserver script (scripts/windows/startserver.vbs)"
    cp scripts/windows/loadmodules.vbs staging/windows-x64/installer/server/loadmodules.vbs || _die "Failed to copy the loadmodules script (scripts/windows/loadmodules.vbs)"
    
    # Copy in the menu pick images and XDG items
    mkdir -p staging/windows-x64/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows-x64/scripts/images || _die "Failed to copy the menu pick images (resources/*.ico)"
    
    # Copy the launch scripts
    cp scripts/windows/serverctl.vbs staging/windows-x64/scripts/serverctl.vbs || _die "Failed to copy the serverctl script (scripts/windows/serverctl.vbs)"
    cp scripts/windows/runpsql.bat staging/windows-x64/scripts/runpsql.bat || _die "Failed to copy the runpsql script (scripts/windows/runpsql.bat)"
    
    PG_DATETIME_SETTING_WINDOWS=`cat staging/windows-x64/include/pg_config.h | grep "#define USE_INTEGER_DATETIMES 1"`

    if [ "x$PG_DATETIME_SETTING_WINDOWS" = "x" ]
    then
          PG_DATETIME_SETTING_WINDOWS="floating-point numbers"
    else
          PG_DATETIME_SETTING_WINDOWS="64-bit integers"
    fi

    if [ -f installer-win64.xml ]; then
        rm -f installer-win64.xml
    fi
    cp installer.xml installer-win64.xml

    _replace @@PG_DATETIME_SETTING_WINDOWS@@ "$PG_DATETIME_SETTING_WINDOWS" installer-win64.xml || _die "Failed to replace the date-time setting in the installer.xml"
    
    _replace @@WIN64MODE@@ "1" installer-win64.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@WINDIR@@ windows-x64 installer-win64.xml || _die "Failed to replace the WINDIR setting in the installer.xml"
    _replace @@SERVICE_SUFFIX@@ "-x64" installer-win64.xml || _die "Failed to replace the SERVICE_SUFFIX setting in the installer.xml"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win64.xml windows || _die "Failed to build the installer"
    
    # Rename the installer
    mv $WD/output/postgresql-$PG_MAJOR_VERSION-windows-installer.exe $WD/output/postgresql-$PG_PACKAGE_VERSION-windows-x64.exe || _die "Failed to rename the installer"

    # Sign the installer
    win32_sign "postgresql-$PG_PACKAGE_VERSION-windows-x64.exe"

    # Copy installer onto the build system
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\component_installers"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q component_installers\\\\postgresql-*-windows-x64.exe"
    scp $WD/output/postgresql-$PG_PACKAGE_VERSION-windows-x64.exe $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/component_installers || _die "Unable to copy installers at windows-x64 build machine."

    cd $WD
    echo "END POST Server Windows-x64"
}

