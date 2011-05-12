#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_server_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/server/source
    
    if [ -e postgres.windows ];
    then
        echo "Removing existing postgres.windows source directory"
        rm -rf postgres.windows  || _die "Couldn't remove the existing postgres.windows source directory (source/postgres.windows)"
    fi
    if [ -e pgadmin.windows ];
    then
        echo "Removing existing pgadmin.windows source directory"
        rm -rf pgadmin.windows  || _die "Couldn't remove the existing pgadmin.windows source directory (source/pgadmin.windows)"
    fi
    if [ -e stackbuilder.windows ];
    then
        echo "Removing existing stackbuilder.windows source directory"
        rm -rf stackbuilder.windows  || _die "Couldn't remove the existing stackbuilder.windows source directory (source/stackbuilder.windows)"
    fi
#    if [ -e pljava.windows ];
#    then
#        echo "Removing existing pljava.windows source directory"
#        rm -rf pljava.windows  || _die "Couldn't remove the existing pljava.windows source directory (source/pljava.windows)"
#    fi
    
    # Remove any existing zip files
    if [ -f $WD/server/source/postgres.zip ];
    then
        echo "Removing existing source archive"
        rm -rf $WD/server/source/postgres.zip || _die "Couldn't remove the existing source archive"
    fi
    if [ -f $WD/server/source/pgadmin.zip ];
    then
        echo "Removing existing pgadmin archive"
        rm -rf $WD/server/source/pgadmin.zip || _die "Couldn't remove the existing pgadmin archive"
    fi
    if [ -f $WD/server/source/stackbuilder.zip ];
    then
        echo "Removing existing stackbuilder archive"
        rm -rf $WD/server/source/stackbuilder.zip || _die "Couldn't remove the existing stackbuilder archive"
    fi
    if [ -f $WD/server/scripts/windows/scripts.zip ];
    then
        echo "Removing existing scripts archive"
        rm -rf $WD/server/scripts/windows/scripts.zip || _die "Couldn't remove the existing scripts archive"
    fi
    if [ -f $WD/server/staging/windows/output.zip ];
    then
        echo "Removing existing output archive"
        rm -rf $WD/server/staging/windows/output.zip || _die "Couldn't remove the existing output archive"
    fi
    
    # Cleanup the build host
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q postgres.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q pgadmin.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q stackbuilder.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q scripts.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q output.zip"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q vc-build.bat"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q output"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q postgres.windows"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q pgadmin.windows"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q stackbuilder.windows"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q createuser"    
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q getlocales"    
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q validateuser"
    
    # Cleanup local files
    if [ -f $WD/server/scripts/windows/vc-build.bat ];
    then
        echo "Removing existing vc-build script"
        rm -rf $WD/server/scripts/windows/vc-build.bat || _die "Couldn't remove the existing vc-build script"
    fi
    
    # Grab a copy of the source tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL postgres.windows || _die "Failed to copy the source code (source/postgres.windows)"
    cp -R pgadmin3-$PG_TARBALL_PGADMIN pgadmin.windows || _die "Failed to copy the source code (source/pgadmin.windows)"
    cp -R stackbuilder stackbuilder.windows || _die "Failed to copy the source code (source/stackbuilder.windows)"
#    mkdir pljava.windows || _die "Failed to create a directory for the plJava binaries"
#    cd pljava.windows
#    tar -zxvf $WD/tarballs/pljava-i686-pc-mingw32-pg$PG_MAJOR_VERSION-$PG_TARBALL_PLJAVA.tar.gz || _die "Failed to extract the pljava binaries"    
#    tar -xvf docs.tar || _die "Failed to extract the pljava docs"
    
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/windows ];
    then
        echo "Removing existing staging directory"
        rm -rf $WD/server/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/windows)"
    mkdir -p $WD/server/staging/windows || _die "Couldn't create the staging directory"

}

################################################################################
# Build
################################################################################

_build_server_windows() {
    
    # Create a build script for VC++
    cd $WD/server/scripts/windows
    
    cat <<EOT > "vc-build.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\vsvars32.bat"

@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET WXWIN=%PGBUILD%\wxWidgets
@SET PGDIR=$PG_PATH_WINDOWS\output

vcbuild /upgrade
vcbuild %1 %2 %3 %4 %5 %6 %7 %8 %9
EOT
    
    # Copy in an appropriate config.pl and buildenv.pl
    cd $WD/server/source/
    cat <<EOT > "postgres.windows/src/tools/msvc/config.pl"
# Configuration arguments for vcbuild.
use strict;
use warnings;

our \$config = {
    asserts=>0,                         # --enable-cassert
    integer_datetimes=>1,               # --enable-integer-datetimes
    nls=>'$PG_PGBUILD_WINDOWS\gettext',        # --enable-nls=<path>
    tcl=>'C:\Tcl-8.5',            # --with-tls=<path>
    perl=>'C:\Perl-5.10',             # --with-perl
    python=>'C:\Python26',         # --with-python=<path>
    krb5=>'',         # --with-krb5=<path>
    ldap=>1,                # --with-ldap
    openssl=>'$PG_PGBUILD_WINDOWS\openssl',     # --with-ssl=<path>
    xml=>'$PG_PGBUILD_WINDOWS\libxml2',
    xslt=>'$PG_PGBUILD_WINDOWS\libxslt',
    iconv=>'$PG_PGBUILD_WINDOWS\iconv',
    zlib=>'$PG_PGBUILD_WINDOWS\zlib',        # --with-zlib=<path>
    uuid=>'$PG_PGBUILD_WINDOWS\uuid-ossp'       # --with-uuid-ossp
};

1;
EOT

    cat <<EOT > "postgres.windows/src/tools/msvc/buildenv.pl"
use strict;
use warnings;

\$ENV{VSINSTALLDIR} = '$PG_VSINSTALLDIR_WINDOWS';
\$ENV{VCINSTALLDIR} = '$PG_VSINSTALLDIR_WINDOWS\VC';
\$ENV{VS90COMNTOOLS} = '$PG_VSINSTALLDIR_WINDOWS\Common7\Tools';
\$ENV{FrameworkDir} = 'C:\WINDOWS\Microsoft.NET\Framework';
\$ENV{FrameworkVersion} = '$PG_FRAMEWORKVERSION_WINDOWS';
\$ENV{Framework35Version} = 'v3.5';
\$ENV{FrameworkSDKDir} = '$PG_FRAMEWORKSDKDIR_WINDOWS';
\$ENV{DevEnvDir} = '$PG_DEVENVDIR_WINDOWS';
\$ENV{M4} = '$PG_PGBUILD_WINDOWS\bison\bin\m4.exe';

\$ENV{PATH} = join
(
    ';' ,
    '$PG_DEVENVDIR_WINDOWS',
    '$PG_VSINSTALLDIR_WINDOWS\VC\BIN',
    '$PG_VSINSTALLDIR_WINDOWS\Common7\Tools',
    '$PG_VSINSTALLDIR_WINDOWS\Common7\Tools\bin',
    '$PG_FRAMEWORKSDKDIR_WINDOWS\bin',
    '$PG_VSINSTALLDIR_WINDOWS\VC\PlatformSDK\Bin',
    'C:\WINDOWS\Microsoft.NET\Framework\\$PG_FRAMEWORKVERSION_WINDOWS',
    '$PG_VSINSTALLDIR_WINDOWS\VC\VCPackages',
    'C:\Program Files\TortoiseCVS',
    '$PG_PGBUILD_WINDOWS\bison\bin',
    '$PG_PGBUILD_WINDOWS\flex\bin',
    '$PG_PGBUILD_WINDOWS\diffutils\bin',
    '$PG_PGBUILD_WINDOWS\patch\bin',
    '$PG_PGBUILD_WINDOWS\gettext\bin',
    '$PG_PGBUILD_WINDOWS\openssl\bin',
    '$PG_PGBUILD_WINDOWS\libxml2\bin',
    '$PG_PGBUILD_WINDOWS\zlib',
    'C:\Perl-5.10\Bin',
    'C:\Python26\Bin',
    'C:\Tcl85\Bin',
    'C:\msys\1.0\bin',
    \$ENV{PATH}
);
         
\$ENV{INCLUDE} = join
(
    ';',
    '$PG_VSINSTALLDIR_WINDOWS\VC\ATLMFC\INCLUDE',
    '$PG_VSINSTALLDIR_WINDOWS\VC\INCLUDE',
    '$PG_VSINSTALLDIR_WINDOWS\VC\PlatformSDK\include',
    '$PG_FRAMEWORKSDKDIR_WINDOWS\include',
    '$PG_PGBUILD_WINDOWS\OpenSSL\include',
    \$ENV{INCLUDE}
);

\$ENV{LIB} = join
(
    ';',
    '$PG_VSINSTALLDIR_WINDOWS\VC\ATLMFC\LIB',
    '$PG_VSINSTALLDIR_WINDOWS\VC\LIB',
    '$PG_VSINSTALLDIR_WINDOWS\VC\PlatformSDK\lib',
    '$PG_FRAMEWORKSDKDIR_WINDOWS\lib',
    '$PG_PGBUILD_WINDOWS\OpenSSL\lib',
    \$ENV{LIB}
);

\$ENV{LIBPATH} = join
(
    ';',
    'C:\Windows\Microsoft.NET\Framework\\$PG_FRAMEWORKVERSION_WINDOWS',
    '$PG_VSINSTALLDIR_WINDOWS\VC\ATLMFC\LIB'
);

1;
EOT

    # Create a config file for the debugger
    cat <<EOT > "postgres.windows/contrib/pldebugger/settings.projinc"
<?xml version="1.0"?>
<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003" DefaultTargets="all">

    <PropertyGroup>
    
        <!-- Debug build? -->
        <DEBUG>0</DEBUG>

        <!-- PostgreSQL source tree -->
        <PGPATH>..\..\</PGPATH>
        
        <!-- Gettext source tree -->
        <GETTEXTPATH>$PG_PGBUILD_WINDOWS\gettext</GETTEXTPATH>
        
        <!-- OpenSSL source tree -->
        <OPENSSLPATH>$PG_PGBUILD_WINDOWS\OpenSSL</OPENSSLPATH>
        
    </PropertyGroup>
</Project>
EOT
        
    # Zip up the scripts directories and copy them to the build host, then unzip
    cd $WD/server/scripts/windows/
    echo "Copying scripts source tree to Windows build VM"
    zip -r scripts.zip vc-build.bat createuser getlocales validateuser || _die "Failed to pack the scripts source tree (ms-build.bat vc-build.bat, createuser, getlocales, validateuser)"

    scp scripts.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the scripts source tree to the windows build host (scripts.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip scripts.zip" || _die "Failed to unpack the scripts source tree on the windows build host (scripts.zip)"    
    
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\createuser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat createuser.vcproj RELEASE" || _die "Failed to build createuser on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\getlocales; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat getlocales.vcproj RELEASE" || _die "Failed to build getlocales on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\validateuser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat validateuser.vcproj RELEASE" || _die "Failed to build validateuser on the windows build host"
    
    # Move the resulting binaries into place
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\output\\\\installer\\\\server" || _die "Failed to create the server directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\createuser\\\\release\\\\createuser.exe $PG_PATH_WINDOWS\\\\output\\\\installer\\\\server" || _die "Failed to copy the createuser proglet on the windows build host" 
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\getlocales\\\\release\\\\getlocales.exe $PG_PATH_WINDOWS\\\\output\\\\installer\\\\server" || _die "Failed to copy the getlocales proglet on the windows build host" 
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\validateuser\\\\release\\\\validateuser.exe $PG_PATH_WINDOWS\\\\output\\\\installer\\\\server" || _die "Failed to copy the validateuser proglet on the windows build host" 
    
    # Zip up the source directory and copy it to the build host, then unzip
    cd $WD/server/source/
    echo "Copying source tree to Windows build VM"
    rm postgres.windows/contrib/pldebugger/Makefile # Remove the unix makefile so that the build scripts don't try to parse it - we have our own.
    zip -r postgres.zip postgres.windows || _die "Failed to pack the source tree (postgres.windows)"
    scp postgres.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (postgres.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip postgres.zip" || _die "Failed to unpack the source tree on the windows build host (postgres.zip)"
   
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/src/tools/msvc; ./build.bat RELEASE" || _die "Failed to build postgres on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/src/tools/msvc; ./install.bat $PG_PATH_WINDOWS\\\\output" || _die "Failed to install postgres on the windows build host"
    
    # Build the debugger plugins
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/contrib/pldebugger; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pldebugger.proj" || _die "Failed to build the pldebugger plugin"
    
    # Copy the debugger plugins into place
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\output\\\\lib\\\\plugins" || _die "Failed to create the plugins directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\postgres.windows\\\\contrib\\\\pldebugger\\\\pldbgapi.dll $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy the debugger api library on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\postgres.windows\\\\contrib\\\\pldebugger\\\\targetinfo.dll $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy the debuygger target info library on the windows build host"    
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\postgres.windows\\\\contrib\\\\pldebugger\\\\plugin_debugger.dll $PG_PATH_WINDOWS\\\\output\\\\lib\\\\plugins" || _die "Failed to copy the debugger plugin on the windows build host"    
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\postgres.windows\\\\contrib\\\\pldebugger\\\\plugin_profiler.dll $PG_PATH_WINDOWS\\\\output\\\\lib\\\\plugins" || _die "Failed to copy the profiler plugin on the windows build host"    
    
    #####################
    # pgAdmin
    #####################
    echo "Copying pgAdmin source tree to Windows build VM"
    zip -r pgadmin.zip pgadmin.windows || _die "Failed to pack the source tree (pgadmin.windows)"
    scp pgadmin.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (pgadmin.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip pgadmin.zip" || _die "Failed to unpack the source tree on the windows build host (pgadmin.zip)"
  
    # Build the PNG compiler 
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/xtra/png2c; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat png2c.vcproj RELEASE" || _die "Failed to build png2c on the build host"

    # Precompile the PNG images. We need to do this for the build system, as it 
    # won't work over cygwin.
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/pgadmin/include/images; for F in *.png; do echo Compiling \${F}... && ../../../xtra/png2c/Release/png2c.exe \${F} \${F}c ; done"

    # Build the code
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/pgadmin; cmd /c ver_svn.bat"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/pgadmin; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pgadmin3.vcproj RELEASE" || _die "Failed to build pgAdmin on the build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/docs; WXWIN=C:/pgBuild/wxWidgets cmd /c builddocs.bat" || _die "Failed to build the docs on the build host"
        
    # Copy the application files into place
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\"" || _die "Failed to create a directory on the windows build host" || _die "Failed to create the studio directory on the build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\pgadmin\\\\Release\\\\pgAdmin3.exe $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a program file on the windows build host"
    
    # Docs
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\"" || _die "Failed to create a directory on the windows build host"

    # There's no particularly clean way to do this as we don't want all the files, and each language may or may not be completely transated :-(
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\cs_CZ\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\cs_CZ\\\\pgAdmin3.chm \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\cs_CZ\"" || _die "Failed to copy a help file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\cs_CZ\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\cs_CZ\\\\hints\"" || _die "Failed to copy a help file on the windows build host"

    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\de_DE\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\de_DE\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\de_DE\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
    
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\en_US\\\\pgAdmin3.chm \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\"" || _die "Failed to copy a help file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\en_US\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
    
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\es_ES\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\es_ES\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\es_ES\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
    
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fi_FI\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\fi_FI\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fi_FI\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
    
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\fr_FR\\\\pgAdmin3.chm \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\"" || _die "Failed to copy a help file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\fr_FR\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\\\\hints\"" || _die "Failed to copy a help file on the windows build host"

    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\sl_SI\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\sl_SI\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\sl_SI\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
    
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_CN\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\zh_CN\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_CN\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
    
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_TW\\\\hints\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\zh_TW\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_TW\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
                    
    # i18n
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to create a directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\i18n\\\\pg_settings.csv \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to copy an i18n file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\i18n\\\\pgadmin3.lng \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to copy an i18n file on the windows build host"
    
    for LANGCODE in `grep "PUB_TX " $WD/server/source/pgadmin.windows/i18n/Makefile.am | cut -d = -f2`
    do
       ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\\\\$LANGCODE\"" || _die "Failed to create a directory on the windows build host"
        ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\i18n\\\\$LANGCODE\\\\*.mo \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\\\\$LANGCODE\"" || _die "Failed to copy an i18n file on the windows build host"    
     ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\pgadmin\\\\*.ini \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\\"" || _die "Failed to copy ini files on the windows build host"    
    done
    
    #####################
    # StackBuilder
    #####################
    echo "Copying StackBuilder source tree to Windows build VM"
    zip -r stackbuilder.zip stackbuilder.windows || _die "Failed to pack the source tree (stackbuilder.windows)"
    scp stackbuilder.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (stackbuilder.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip stackbuilder.zip" || _die "Failed to unpack the source tree on the windows build host (stackbuilder.zip)"
  
    # Build the code
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/stackbuilder.windows; cmd /c cmake -D WX_ROOT_DIR=C:\\\\pgBuild\\\\wxWidgets -D MSGFMT_EXECUTABLE=C:\\\\pgBuild\\\\gettext\\\\bin\\\\msgfmt -D CMAKE_INSTALL_PREFIX=$PG_PATH_WINDOWS\\\\output\\\\StackBuilder ." || _die "Failed to configure pgAdmin on the build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/stackbuilder.windows; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat stackbuilder.vcproj RELEASE" || _die "Failed to build stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/stackbuilder.windows; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat INSTALL.vcproj RELEASE" || _die "Failed to install stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS "cmd /c mv $PG_PATH_WINDOWS\\\\output\\\\StackBuilder\\\\bin\\\\stackbuilder.exe $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to relocate the stackbuilder executable on the build host"
    ssh $PG_SSH_WINDOWS "cmd /c rd $PG_PATH_WINDOWS\\\\output\\\\StackBuilder\\\\bin" || _die "Failed to remove the stackbuilder bin directory on the build host"

    # Copy the various support files into place
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\vcredist\\\\vcredist_x86.exe $PG_PATH_WINDOWS\\\\output\\\\installer" || _die "Failed to copy the VC++ runtimes on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\OpenSSL\\\\bin\\\\ssleay32.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\OpenSSL\\\\bin\\\\libeay32.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\iconv\\\\bin\\\\iconv.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\gettext\\\\bin\\\\libintl-8.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\gettext\\\\bin\\\\libiconv-2.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\libxml2\\\\bin\\\\libxml2.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\libxslt\\\\bin\\\\libxslt.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\zlib\\\\zlib1.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\gettext\\\\include\\\\*.h $PG_PATH_WINDOWS\\\\output\\\\include" || _die "Failed to copy a third party include files on the windows build host"

    # Copy the wxWidgets libraries    
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxbase28u_net_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxbase28u_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxbase28u_xml_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_adv_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_aui_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_core_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_html_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy 
a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_stc_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_xrc_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\output; cmd /c zip -r ..\\\\output.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output.zip $WD/server/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output.zip)"
    unzip $WD/server/staging/windows/output.zip -d $WD/server/staging/windows/ || _die "Failed to unpack the built source tree ($WD/staging/windows/output.zip)"
    rm $WD/server/staging/windows/output.zip

    # sign stackbuilder
    win32_sign "stackbuilder.exe" "$WD/server/staging/windows/StackBuilder/bin"

    # Install the PostgreSQL docs
    mkdir -p $WD/server/staging/windows/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $WD/server/staging/windows/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -R $WD/server/source/postgres.windows/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"
    
    # Copy in the plDebugger docs & SQL script
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/README.pldebugger $WD/server/staging/windows/doc
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/pldbgapi.sql $WD/server/staging/windows/share/contrib
     
    # Copy in the pljava binaries/docs
#    cd $WD/server/source/
#    echo "Installing pl/java"
#    cp pljava.windows/*.jar $WD/server/staging/windows/lib || _die "Failed to install the pljava jar files."
#    cp pljava.windows/*.dll $WD/server/staging/windows/lib || _die "Failed to install the pljava dll files."
#    mkdir $WD/server/staging/windows/share/pljava || _die "Failed to create a directory for the pljava SQL scripts."
#    cp pljava.windows/*.sql $WD/server/staging/windows/share/pljava || _die "Failed to install the pljava SQL scripts."
#    cp -R pljava.windows/docs $WD/server/staging/windows/doc/pljava || _die "Failed to install the pljava docs."
    
    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_server_windows() {

    cd $WD/server

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/windows/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.gif" "$WD/server/staging/windows/doc/" || _die "Failed to install the welcome logo"

    cp "$WD/scripts/runAsAdmin.vbs" "$WD/server/staging/windows" || _die "Failed to copy the runAsRoot script"
    _replace @@SERVER_SUFFIX@@ "x86" $WD/server/staging/windows/runAsAdmin.vbs || _die "Failed to replace the SERVER_SUFFIX setting in the runAsAdmin.vbs"
    #Creating a archive of the binaries
    mkdir -p $WD/server/staging/windows/pgsql || _die "Failed to create the directory for binaries "
    cd $WD/server/staging/windows
    cp -R bin doc include lib pgAdmin* share StackBuilder symbols pgsql/ || _die "Failed to copy the binaries to the pgsql directory"

    zip -rq postgresql-$PG_PACKAGE_VERSION-windows-binaries.zip pgsql || _die "Failed to archive the postgresql binaries"
    mv postgresql-$PG_PACKAGE_VERSION-windows-binaries.zip $WD/output/ || _die "Failed to move the archive to output folder"

    rm -rf pgsql || _die "Failed to remove the binaries directory" 

    cd $WD/server

    # Setup the installer scripts. 
    mkdir -p staging/windows/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/installruntimes.vbs staging/windows/installer/installruntimes.vbs || _die "Failed to copy the installruntimes script ($WD/scripts/windows/installruntimes.vbs)"
    cp scripts/windows/prerun_checks.vbs staging/windows/installer/prerun_checks.vbs || _die "Failed to copy the prerun_checks.vbs script ($WD/scripts/windows/prerun_checks.vbs)"
    cp scripts/windows/initcluster.vbs staging/windows/installer/server/initcluster.vbs || _die "Failed to copy the loadmodules script (scripts/windows/initcluster.vbs)"
    cp scripts/windows/startupcfg.vbs staging/windows/installer/server/startupcfg.vbs || _die "Failed to copy the startupcfg script (scripts/windows/startupcfg.vbs)"
    cp scripts/windows/createshortcuts.vbs staging/windows/installer/server/createshortcuts.vbs || _die "Failed to copy the createshortcuts script (scripts/windows/createshortcuts.vbs)"
    cp scripts/windows/startserver.vbs staging/windows/installer/server/startserver.vbs || _die "Failed to copy the startserver script (scripts/windows/startserver.vbs)"
    cp scripts/windows/loadmodules.vbs staging/windows/installer/server/loadmodules.vbs || _die "Failed to copy the loadmodules script (scripts/windows/loadmodules.vbs)"
    
    # Copy in the menu pick images and XDG items
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.ico)"
    
    # Copy the launch scripts
    cp scripts/windows/serverctl.vbs staging/windows/scripts/serverctl.vbs || _die "Failed to copy the serverctl script (scripts/windows/serverctl.vbs)"
    cp scripts/windows/runpsql.bat staging/windows/scripts/runpsql.bat || _die "Failed to copy the runpsql script (scripts/windows/runpsql.bat)"
    
    PG_DATETIME_SETTING_WINDOWS=`cat staging/windows/include/pg_config.h | grep "#define USE_INTEGER_DATETIMES 1"`

    if [ "x$PG_DATETIME_SETTING_WINDOWS" = "x" ]
    then
          PG_DATETIME_SETTING_WINDOWS="floating-point numbers"
    else
          PG_DATETIME_SETTING_WINDOWS="64-bit integers"
    fi

    if [ -f installer-win.xml ]; then
      rm -f installer-win.xml
    fi
    cp installer.xml installer-win.xml

    _replace @@PG_DATETIME_SETTING_WINDOWS@@ "$PG_DATETIME_SETTING_WINDOWS" installer-win.xml || _die "Failed to replace the date-time setting in the installer.xml"

    _replace @@WIN64MODE@@ "0" installer-win.xml || _die "Failed to replace the WIN64MODE setting in the installer.xml"
    _replace @@WINDIR@@ windows installer-win.xml || _die "Failed to replace the WINDIR setting in the installer.xml"
    _replace @@SERVICE_SUFFIX@@ "" installer-win.xml || _die "Failed to replace the SERVICE_SUFFIX setting in the installer.xml"

    
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer-win.xml windows || _die "Failed to build the installer"
    
    # Rename the installer
    mv $WD/output/postgresql-$PG_MAJOR_VERSION-windows-installer.exe $WD/output/postgresql-$PG_PACKAGE_VERSION-windows.exe || _die "Failed to rename the installer"

    # Sign the installer
    win32_sign "postgresql-$PG_PACKAGE_VERSION-windows.exe"
    
    cd $WD
}

