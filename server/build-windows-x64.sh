#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_server_windows_x64() {

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
    #if [ -e pljava.windows-x64 ];
    #then
    #    echo "Removing existing pljava.windows-x64 source directory"
    #    rm -rf pljava.windows-x64  || _die "Couldn't remove the existing pljava.windows-x64 source directory (source/pljava.windows-x64)"
    #fi
    
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
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q vc-build.bat"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c del /S /Q vc-build-x64.bat"
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
    #mkdir pljava.windows-x64 || _die "Failed to create a directory for the plJava binaries"
    #cd pljava.windows-x64
    #tar -zxvf $WD/tarballs/pljava-i686-pc-mingw32-pg8.4-$PG_TARBALL_PLJAVA.tar.gz || _die "Failed to extract the pljava binaries"    
    #tar -xvf docs.tar || _die "Failed to extract the pljava docs"
    
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/windows-x64 ];
    then
        echo "Removing existing staging directory"
        rm -rf $WD/server/staging/windows-x64 || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/windows-x64)"
    mkdir -p $WD/server/staging/windows-x64 || _die "Couldn't create the staging directory"

}

################################################################################
# Build
################################################################################

_build_server_windows_x64() {
    
    # Create a build script for VC++
    cd $WD/server/scripts/windows
    
    cat <<EOT > "vc-build.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS_X64\VC\vcvarsall.bat" amd64

@SET PGBUILD=$PG_PGBUILD_WINDOWS_X64
@SET WXWIN=%PGBUILD%\wxWidgets
@SET PGDIR=$PG_PATH_WINDOWS_X64\output

vcbuild /upgrade
vcbuild %1 %2 %3 %4 %5 %6 %7 %8 %9
EOT

# Create vc-build-x64.sh which does not contain vcbuild /upgrade command because 
# in this case stackbuilder runs in DEBUG mode. vc-build.bat is used only for createuser 
# and other utilities which are in scripts folder.    
    cat <<EOT > "vc-build-x64.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS_X64\VC\vcvarsall.bat" amd64

@SET PGBUILD=$PG_PGBUILD_WINDOWS_X64
@SET WXWIN=%PGBUILD%\wxWidgets
@SET PGDIR=$PG_PATH_WINDOWS_X64\output

vcbuild %1 %2 %3 %4 %5 %6 %7 %8 %9
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
    nls=>'$PG_PGBUILD_WINDOWS_X64\gettext',        # --enable-nls=<path>
    perl=>'C:\Perl-5.14',             # --with-perl
    python=>'C:\Python32',         # --with-python=<path>
    tcl=>'C:\Tcl-8.5',            # --with-tls=<path>
    ldap=>1,                # --with-ldap
    openssl=>'$PG_PGBUILD_WINDOWS_X64\OpenSSL',     # --with-ssl=<path>
    xml=>'$PG_PGBUILD_WINDOWS_X64\libxml2',
    xslt=>'$PG_PGBUILD_WINDOWS_X64\libxslt',
    iconv=>'$PG_PGBUILD_WINDOWS_X64\iconv',
    zlib=>'$PG_PGBUILD_WINDOWS_X64\zlib',        # --with-zlib=<path>
    uuid=>'$PG_PGBUILD_WINDOWS_X64\uuid-ossp'       # --with-uuid-ossp
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
\$ENV{M4} = '$PG_PGBUILD_WINDOWS_X64\bison\bin\m4.exe';

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
    'C:\Program Files\TortoiseCVS',
    '$PG_PGBUILD_WINDOWS_X64\bison\bin',
    '$PG_PGBUILD_WINDOWS_X64\flex\bin',
    '$PG_PGBUILD_WINDOWS_X64\diffutils\bin',
    '$PG_PGBUILD_WINDOWS_X64\patch\bin',
    '$PG_PGBUILD_WINDOWS_X64\gettext\bin',
    '$PG_PGBUILD_WINDOWS_X64\OpenSSL\bin',
    '$PG_PGBUILD_WINDOWS_X64\libxml2\bin',
    '$PG_PGBUILD_WINDOWS_X64\zlib\bin',
    'C:\Perl-5.14\bin',
    'C:\Python32',
    'C:\msys\1.0\bin',
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
    '$PG_PGBUILD_WINDOWS_X64\OpenSSL\include',
    \$ENV{INCLUDE}
);

\$ENV{LIB} = join
(
    ';',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\ATLMFC\LIB',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\LIB',
    '$PG_VSINSTALLDIR_WINDOWS_X64\VC\PlatformSDK\lib',
    '$PG_FRAMEWORKSDKDIR_WINDOWS_X64\lib',
    '$PG_PGBUILD_WINDOWS_X64\OpenSSL\lib',
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
        <GETTEXTPATH>$PG_PGBUILD_WINDOWS_X64\gettext</GETTEXTPATH>
        
        <!-- OpenSSL source tree -->
        <OPENSSLPATH>$PG_PGBUILD_WINDOWS_X64\OpenSSL</OPENSSLPATH>
        
    </PropertyGroup>
</Project>
EOT

        
    # Zip up the scripts directories and copy them to the build host, then unzip
    cd $WD/server/scripts/windows/
    echo "Copying scripts source tree to Windows build VM"
    zip -r scripts.zip vc-build-x64.bat vc-build.bat createuser getlocales validateuser || _die "Failed to pack the scripts source tree (ms-build.bat vc-build-x64.bat vc-build.bat, createuser, getlocales, validateuser)"

    scp scripts.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the scripts source tree to the windows-x64 build host (scripts.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip scripts.zip" || _die "Failed to unpack the scripts source tree on the windows-x64 build host (scripts.zip)"    
    
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\createuser; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build.bat /platform:x64 createuser.vcproj RELEASE" || _die "Failed to build createuser on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\getlocales; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build.bat /platform:x64 getlocales.vcproj RELEASE" || _die "Failed to build getlocales on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\validateuser; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build.bat /platform:x64 validateuser.vcproj RELEASE" || _die "Failed to build validateuser on the windows-x64 build host"
    
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
    scp postgres-win64.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the source tree to the windows-x64 build host (postgres-win64.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip postgres-win64.zip" || _die "Failed to unpack the source tree on the windows-x64 build host (postgres-win64.zip)"
   
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS_X64 "set; cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/src/tools/msvc; ./build.bat RELEASE" || _die "Failed to build postgres on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/src/tools/msvc; ./install.bat $PG_PATH_WINDOWS_X64\\\\output" || _die "Failed to install postgres on the windows-x64 build host"
    
    # Build the debugger plugins
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/postgres.windows-x64/contrib/pldebugger; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat pldebugger.proj" || _die "Failed to build the pldebugger plugin"
    
    # Copy the debugger plugins into place
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir $PG_PATH_WINDOWS_X64\\\\output\\\\lib\\\\plugins" || _die "Failed to create the plugins directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\contrib\\\\pldebugger\\\\pldbgapi.dll $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy the debugger api library on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\contrib\\\\pldebugger\\\\targetinfo.dll $PG_PATH_WINDOWS_X64\\\\output\\\\lib" || _die "Failed to copy the targetinfo library on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\contrib\\\\pldebugger\\\\plugin_debugger.dll $PG_PATH_WINDOWS_X64\\\\output\\\\lib\\\\plugins" || _die "Failed to copy the debugger plugin on the windows-x64 build host"    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\contrib\\\\pldebugger\\\\plugin_profiler.dll $PG_PATH_WINDOWS_X64\\\\output\\\\lib\\\\plugins" || _die "Failed to copy the profiler plugin on the windows-x64 build host"    
    
    #####################
    # pgAdmin
    #####################
    echo "Copying pgAdmin source tree to Windows build VM"
    zip -r pgadmin-win64.zip pgadmin.windows-x64 || _die "Failed to pack the source tree (pgadmin.windows-x64)"
    scp pgadmin-win64.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the source tree to the windows-x64 build host (pgadmin-win64.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip pgadmin-win64.zip" || _die "Failed to unpack the source tree on the windows-x64 build host (pgadmin-win64.zip)"
  
    # Build the PNG compiler 
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/xtra/png2c; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build.bat png2c.vcproj RELEASE" || _die "Failed to build png2c on the build host"

    # Precompile the PNG images. We need to do this for the build system, as it 
    # won't work over cygwin.
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/pgadmin/include/images; for F in *.png; do echo Compiling \${F}... && ../../../xtra/png2c/Release/png2c.exe \${F} \${F}c ; done"
 
    # Build the code
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/pgadmin; cmd /c ver_svn.bat"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/pgadmin; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build.bat /platform:x64 pgadmin3.vcproj RELEASE" || _die "Failed to build pgAdmin on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/pgadmin.windows-x64/docs; WXWIN=C:/pgBuild/wxWidgets cmd /c builddocs.bat" || _die "Failed to build the docs on the build host"
        
    # Copy the application files into place
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\"" || _die "Failed to create a directory on the windows-x64 build host" || _die "Failed to create the studio directory on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\pgadmin\\\\Release\\\\pgAdmin3.exe $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a program file on the windows-x64 build host"
    
    # Docs
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\"" || _die "Failed to create a directory on the windows-x64 build host"

    # There's no particularly clean way to do this as we don't want all the files, and each language may or may not be completely transated :-(
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\cs_CZ\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\cs_CZ\\\\pgAdmin3.chm \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\cs_CZ\"" || _die "Failed to copy a help file on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\cs_CZ\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\cs_CZ\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"

    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\de_DE\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\de_DE\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\de_DE\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\en_US\\\\pgAdmin3.chm \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\"" || _die "Failed to copy a help file on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\en_US\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\es_ES\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\es_ES\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\es_ES\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\fi_FI\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\fi_FI\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\fi_FI\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\fr_FR\\\\pgAdmin3.chm \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\"" || _die "Failed to copy a help file on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\fr_FR\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"

    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\sl_SI\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\sl_SI\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\sl_SI\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\zh_CN\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\zh_CN\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\zh_CN\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mkdir \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\zh_TW\\\\hints\"" || _die "Failed to create a directory on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\pgadmin.windows-x64\\\\docs\\\\zh_TW\\\\hints\\\\*.html \"$PG_PATH_WINDOWS_X64\\\\output\\\\pgAdmin III\\\\docs\\\\zh_TW\\\\hints\"" || _die "Failed to copy a help file on the windows-x64 build host"
                    
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
    echo "Copying StackBuilder source tree to Windows build VM"
    zip -r stackbuilder-win64.zip stackbuilder.windows-x64 || _die "Failed to pack the source tree (stackbuilder.windows-x64)"
    scp stackbuilder-win64.zip $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64 || _die "Failed to copy the source tree to the windows-x64 build host (stackbuilder-win64.zip)"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64; cmd /c unzip stackbuilder-win64.zip" || _die "Failed to unpack the source tree on the windows-x64 build host (stackbuilder-win64.zip)"
  
    # Build the code
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/stackbuilder.windows-x64; cmd /c "C:\\\\pgBuild\\\\CMake2.8\\\\bin\\\\cmake" -G Visual\ Studio\ 9\ 2008\ Win64 -D WX_ROOT_DIR=C:\\\\pgBuild\\\\wxWidgets -D MSGFMT_EXECUTABLE=C:\\\\pgBuild\\\\gettext\\\\bin\\\\msgfmt -D CMAKE_INSTALL_PREFIX=$PG_PATH_WINDOWS_X64\\\\output\\\\StackBuilder ." || _die "Failed to configure pgAdmin on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/stackbuilder.windows-x64; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat /platform:x64 stackbuilder.vcproj RELEASE" || _die "Failed to build stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64/stackbuilder.windows-x64; cmd /c $PG_PATH_WINDOWS_X64\\\\vc-build-x64.bat /platform:x64 INSTALL.vcproj RELEASE" || _die "Failed to install stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c mv $PG_PATH_WINDOWS_X64\\\\output\\\\StackBuilder\\\\bin\\\\stackbuilder.exe $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to relocate the stackbuilder executable on the build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c rd $PG_PATH_WINDOWS_X64\\\\output\\\\StackBuilder\\\\bin" || _die "Failed to remove the stackbuilder bin directory on the build host"

    # Copy the various support files into place
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\vcredist\\\\vcredist_x64.exe $PG_PATH_WINDOWS_X64\\\\output\\\\installer" || _die "Failed to copy the VC++ runtimes on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\OpenSSL\\\\bin\\\\ssleay32.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\OpenSSL\\\\bin\\\\libeay32.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\libxml2\\\\bin\\\\libxml2.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\libxslt\\\\bin\\\\libxslt.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\libiconv\\\\bin\\\\libiconv-2.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\gettext\\\\bin\\\\libintl-8.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\zlib\\\\bin\\\\zlib1.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\gettext\\\\include\\\\*.h $PG_PATH_WINDOWS_X64\\\\output\\\\include" || _die "Failed to copy a third party include files on the windows-x64 build host"

    # Copy the wxWidgets libraries
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxbase28u_net_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxbase28u_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxbase28u_xml_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_adv_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_aui_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_core_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_html_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_stc_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy C:\\\\pgBuild\\\\wxWidgets\\\\lib\\\\vc_dll\\\\wxmsw28u_xrc_vc_custom.dll $PG_PATH_WINDOWS_X64\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows-x64 build host"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to Unix host"
    ssh $PG_SSH_WINDOWS_X64 "cd $PG_PATH_WINDOWS_X64\\\\output; zip -r ..\\\\output.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output)"
    scp $PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output.zip $WD/server/staging/windows-x64 || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS_X64:$PG_PATH_WINDOWS_X64/output.zip)"
    unzip $WD/server/staging/windows-x64/output.zip -d $WD/server/staging/windows-x64/ || _die "Failed to unpack the built source tree ($WD/staging/windows-x64/output.zip)"
    rm $WD/server/staging/windows-x64/output.zip

	win32_sign "stackbuilder.exe" "$WD/server/staging/windows-x64/bin"
    
    # Install the PostgreSQL docs
    mkdir -p $WD/server/staging/windows-x64/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $WD/server/staging/windows-x64/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -R $WD/server/source/postgres.windows-x64/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"
    
    # Copy in the plDebugger docs & SQL script
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/README.pldebugger $WD/server/staging/windows-x64/doc
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/pldbgapi.sql $WD/server/staging/windows-x64/share/contrib
     
    # Copy in the pljava binaries/docs
    #cd $WD/server/source/
    #echo "Installing pl/java"
    #cp pljava.windows-x64/deploy.jar $WD/server/staging/windows-x64/lib || _die "Failed to install the deploy.jar files."
    #cp pljava.windows-x64/examples.jar $WD/server/staging/windows-x64/lib || _die "Failed to install the examples.jar files."
    #cp pljava.windows-x64/pljava.jar $WD/server/staging/windows-x64/lib || _die "Failed to install the pljava.jar files."
    #cp pljava.windows-x64/*.dll $WD/server/staging/windows-x64/lib || _die "Failed to install the pljava dll files."
    #mkdir -p $WD/server/staging/windows-x64/share/pljava || _die "Failed to create a directory for the pljava SQL scripts."
    #cp pljava.windows-x64/install.sql $WD/server/staging/windows-x64/share/pljava || _die "Failed to install the install.sql SQL scripts."
    #cp pljava.windows-x64/uninstall.sql $WD/server/staging/windows-x64/share/pljava || _die "Failed to install the uninstall.sql SQL scripts."
    #cp -R pljava.windows-x64/docs $WD/server/staging/windows-x64/doc/pljava || _die "Failed to install the pljava docs."
    
    cd $WD
}


################################################################################
# Post process
################################################################################

_postprocess_server_windows_x64() {

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
    cp scripts/windows/installruntimes.vbs staging/windows-x64/installer/installruntimes.vbs || _die "Failed to copy the installruntimes script ($WD/scripts/windows/installruntimes.vbs)"
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

    # Delete old installers from regresson setup 
    ssh $PG_SSH_WINDOWS_X64 "cd C:\\\\buildfarm\\\\PG91\\\\installers ; cmd /c del /S /Q postgresql-*-windows-x64.exe"
    
    # Copy installer into the regression system/folder
    scp $WD/output/postgresql-$PG_PACKAGE_VERSION-windows-x64.exe $PG_SSH_WINDOWS_X64:/cygdrive/c/buildfarm/PG91/installers/ || _die "Unable to copy installers at windows-x64 build machine."

    # Delete old regress.dll and pg_regress.exe from regression setup 
    ssh $PG_SSH_WINDOWS_X64 "cd C:\\\\buildfarm\\\\PG91\\\\Release\\\\regress ; cmd /c del /S /Q regress.dll"
    ssh $PG_SSH_WINDOWS_X64 "cd C:\\\\buildfarm\\\\PG91\\\\Release\\\\pg_regress ; cmd /c del /S /Q pg_regress.exe "

    #Copy Regress binary & dll to regression setup
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\Release\\\\regress\\\\regress.dll C:\\\\buildfarm\\\\PG91\\\\Release\\\\regress" || _die "Failed to copy a regress.dll to regression setup"
    ssh $PG_SSH_WINDOWS_X64 "cmd /c copy $PG_PATH_WINDOWS_X64\\\\postgres.windows-x64\\\\Release\\\\pg_regress\\\\pg_regress.exe C:\\\\buildfarm\\\\PG91\\\\Release\\\\pg_regress" || _die "Failed to copy pg_regress.exe to regression setup"
    

    # Delete the old regress source folder from regression 
    ssh $PG_SSH_WINDOWS_X64 "cd /cygdrive/c/buildfarm/PG91/src/test/ ; cmd /c rd /S /Q regress"
    
    # Copy the regress source code folder to regression 
    scp -r $WD/server/source/postgres.windows-x64/src/test/regress  $PG_SSH_WINDOWS_X64:/cygdrive/c/buildfarm/PG91/src/test/
    
    cd $WD
}

