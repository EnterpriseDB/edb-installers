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
    if [ -e pljava.windows ];
    then
        echo "Removing existing pljava.windows source directory"
        rm -rf pljava.windows  || _die "Couldn't remove the existing pljava.windows source directory (source/pljava.windows)"
    fi
	
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
        rm -rf $WD/server/scripts/windows/output.zip || _die "Couldn't remove the existing output archive"
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
	mkdir pljava.windows || _die "Failed to create a directory for the plJava binaries"
	cd pljava.windows
	tar -zxvf $WD/tarballs/pljava-i686-pc-mingw32-pg8.3-$PG_TARBALL_PLJAVA.tar.gz || _die "Failed to extract the pljava binaries"	
	tar -xvf docs.tar || _die "Failed to extract the pljava docs"
	
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

@SET PGBUILD=C:\pgBuild
@SET WXWIN=%PGBUILD%\wxWidgets
@SET PGDIR=$PG_PATH_WINDOWS\output

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
    nls=>'C:\pgBuild\gettext',        # --enable-nls=<path>
    tcl=>'C:\tcl',            # --with-tls=<path>
    perl=>'C:\perl',             # --with-perl
    python=>'C:\python25',         # --with-python=<path>
    krb5=>'C:\pgBuild\krb5',         # --with-krb5=<path>
    ldap=>1,                # --with-ldap
    openssl=>'C:\pgBuild\openssl',     # --with-ssl=<path>
    xml=>'C:\pgBuild\libxml2',
    xslt=>'C:\pgBuild\libxslt',
    iconv=>'C:\pgBuild\iconv',
    zlib=>'C:\pgBuild\zlib'        # --with-zlib=<path>
};

1;
EOT

    cat <<EOT > "postgres.windows/src/tools/msvc/buildenv.pl"
use strict;
use warnings;

\$ENV{VSINSTALLDIR} = 'C:\Program Files\Microsoft Visual Studio 8';
\$ENV{VCINSTALLDIR} = 'C:\Program Files\Microsoft Visual Studio 8\VC';
\$ENV{VS80COMNTOOLS} = 'C:\Program Files\Microsoft Visual Studio 8\Common7\Tools';
\$ENV{FrameworkDir} = 'C:\WINDOWS\Microsoft.NET\Framework';
\$ENV{FrameworkVersion} = 'v2.0.50727';
\$ENV{FrameworkSDKDir} = 'C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0';
\$ENV{DevEnvDir} = 'C:\Program Files\Microsoft Visual Studio 8\Common7\IDE';

\$ENV{PATH} = join
(
    ';' ,
    'C:\Program Files\Microsoft Visual Studio 8\Common7\IDE',
    'C:\Program Files\Microsoft Visual Studio 8\VC\BIN',
    'C:\Program Files\Microsoft Visual Studio 8\Common7\Tools',
    'C:\Program Files\Microsoft Visual Studio 8\Common7\Tools\bin',
    'C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0\bin',
    'C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK\Bin',
    'C:\WINDOWS\Microsoft.NET\Framework\v2.0.50727',
    'C:\Program Files\Microsoft Visual Studio 8\VC\VCPackages',
    'C:\Program Files\TortoiseCVS',
    'C:\pgBuild\bison\bin',
    'C:\pgBuild\flex\bin',
    'C:\pgBuild\diffutils\bin',
    'C:\pgBuild\patch\bin',
    'C:\pgBuild\gettext\bin',
    'C:\pgBuild\openssl\bin',
    'C:\pgBuild\krb5\bin\i386',
    'C:\pgBuild\libxml2\bin',
    'C:\pgBuild\zlib',
    'C:\Perl\Bin',
    'C:\Python25\Bin',
    'C:\Tcl\Bin',
    'C:\msys\1.0\bin',
    \$ENV{PATH}
);
         
\$ENV{INCLUDE} = join
(
    ';',
    'C:\Program Files\Microsoft Visual Studio 8\VC\ATLMFC\INCLUDE',
    'C:\Program Files\Microsoft Visual Studio 8\VC\INCLUDE',
    'C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK\include',
    'C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0\include',
    'C:\pgBuild\OpenSSL\include',
    \$ENV{INCLUDE}
);

\$ENV{LIB} = join
(
    ';',
    'C:\Program Files\Microsoft Visual Studio 8\VC\ATLMFC\LIB',
    'C:\Program Files\Microsoft Visual Studio 8\VC\LIB',
    'C:\Program Files\Microsoft Visual Studio 8\VC\PlatformSDK\lib',
    'C:\Program Files\Microsoft Visual Studio 8\SDK\v2.0\lib',
    'C:\pgBuild\OpenSSL\lib',
    \$ENV{LIB}
);

\$ENV{LIBPATH} = join
(
    ';',
    'C:\Windows\Microsoft.NET\Framework\v2.0.50727',
    'C:\Program Files\Microsoft Visual Studio 8\VC\ATLMFC\LIB'
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
        <GETTEXTPATH>C:\pgBuild\gettext</GETTEXTPATH>
        
        <!-- OpenSSL source tree -->
        <OPENSSLPATH>C:\pgBuild\OpenSSL</OPENSSLPATH>
        
        <!-- Kerberos source tree -->
        <KERBEROSPATH>C:\pgBuild\krb5</KERBEROSPATH>

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
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/createuser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat createuser.vcproj" || _die "Failed to build createuser on the windows build host"
	ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/getlocales; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat getlocales.vcproj" || _die "Failed to build getlocales on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/validateuser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat validateuser.vcproj" || _die "Failed to build validateuser on the windows build host"
	
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
   
    # Build the code
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/pgadmin; cmd /c ver_svn.bat"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/pgadmin; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pgadmin3.vcproj RELEASE" || _die "Failed to build pgAdmin on the build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/xtra/pgagent; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pgagent.vcproj RELEASE" || _die "Failed to build pgAgent on the build host"
	ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/xtra/pgaevent; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pgaevent.vcproj RELEASE" || _die "Failed to build pgaevent on the build host"
	ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows/docs; cmd /c builddocs.bat" || _die "Failed to build the docs on the build host"
		
	# Copy the application files into place
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\"" || _die "Failed to create a directory on the windows build host" || _die "Failed to create the studio directory on the build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\pgadmin\\\\Release\\\\pgAdmin3.exe $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a program file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\xtra\\\\pgAgent\\\\Release\\\\pgAgent.exe $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a program file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\xtra\\\\pgaevent\\\\Release\\\\pgaevent.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a program file on the windows build host"
	
	# Docs
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\"" || _die "Failed to create a directory on the windows build host"

    # There's no particularly clean way to do this as we don't want all the files, and each language may or may not be completely transated :-(
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\de_DE\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\de_DE\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\de_DE\"" || _die "Failed to copy a help file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\de_DE\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\de_DE\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
	
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\en_US\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\"" || _die "Failed to copy a help file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\en_US\\\\pgAdmin3.chm \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\"" || _die "Failed to copy a help file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\en_US\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\en_US\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
	
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\es_ES\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\es_ES\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\es_ES\"" || _die "Failed to copy a help file on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\es_ES\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\es_ES\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
	
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fi_FI\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\fi_FI\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fi_FI\"" || _die "Failed to copy a help file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\fi_FI\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fi_FI\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
	
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\fr_FR\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\"" || _die "Failed to copy a help file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\fr_FR\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\fr_FR\\\\hints\"" || _die "Failed to copy a help file on the windows build host"

	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\it_IT\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\it_IT\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\it_IT\"" || _die "Failed to copy a help file on the windows build host"

	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\sl_SI\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\sl_SI\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\sl_SI\"" || _die "Failed to copy a help file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\sl_SI\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\sl_SI\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
	
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_CN\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\zh_CN\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_CN\"" || _die "Failed to copy a help file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\zh_CN\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_CN\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
	
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_TW\\\\hints\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\zh_TW\\\\tips.txt \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_TW\"" || _die "Failed to copy a help file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\docs\\\\zh_TW\\\\hints\\\\*.html \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\docs\\\\zh_TW\\\\hints\"" || _die "Failed to copy a help file on the windows build host"
					
	# i18n
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\i18n\\\\pg_settings.csv \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to copy an i18n file on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\i18n\\\\pgadmin3.lng \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\"" || _die "Failed to copy an i18n file on the windows build host"
	
	for LANGCODE in `grep "PUB_TX " $WD/server/source/pgadmin.windows/i18n/Makefile.am | cut -d = -f2`
	do
   	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\\\\$LANGCODE\"" || _die "Failed to create a directory on the windows build host"
	    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\i18n\\\\$LANGCODE\\\\*.mo \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\i18n\\\\$LANGCODE\"" || _die "Failed to copy an i18n file on the windows build host"	
	done
	
	# Misc					
	ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\scripts\"" || _die "Failed to create a directory on the windows build host"
	ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\xtra\\\\pgAgent\\\\pgAgent.sql \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin III\\\\scripts\"" || _die "Failed to copy a program file on the windows build host"

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
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\krb5\\\\bin\\\\i386\\\\comerr32.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\krb5\\\\bin\\\\i386\\\\krb5_32.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\krb5\\\\bin\\\\i386\\\\k5sprt32.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\krb5\\\\bin\\\\i386\\\\gssapi32.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\libxml2\\\\bin\\\\libxml2.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\libxslt\\\\bin\\\\libxslt.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\pgBuild\\\\zlib\\\\zlib1.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy C:\\\\Windows\\\\System32\\\\msvcr71.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host"
	
    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to Unix host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\output; cmd /c zip -r ..\\\\output.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output)"
    scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output.zip $WD/server/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output.zip)"
    unzip $WD/server/staging/windows/output.zip -d $WD/server/staging/windows/ || _die "Failed to unpack the built source tree ($WD/staging/windows/output.zip)"
    rm $WD/server/staging/windows/output.zip
	
	# Install the PostgreSQL docs
	mkdir -p $WD/server/staging/windows/doc/postgresql/html || _die "Failed to create the doc directory"
	cd $WD/server/staging/windows/doc/postgresql/html || _die "Failed to change to the doc directory"
	tar -zxvf $WD/server/source/postgres.windows/doc/postgres.tar.gz || _die "Failed to unpack the PostgreSQL documentation"
	
	# Copy in the plDebugger docs
	cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/README.pldebugger $WD/server/staging/osx/doc
	 
	# Copy in the pljava binaries/docs
	cd $WD/server/source/
	echo "Installing pl/java"
	cp pljava.windows/*.jar $WD/server/staging/windows/lib || _die "Failed to install the pljava jar files."
	cp pljava.windows/*.dll $WD/server/staging/windows/lib || _die "Failed to install the pljava dll files."
	mkdir $WD/server/staging/windows/share/pljava || _die "Failed to create a directory for the pljava SQL scripts."
	cp pljava.windows/*.sql $WD/server/staging/windows/share/pljava || _die "Failed to install the pljava SQL scripts."
	cp -R pljava.windows/docs $WD/server/staging/windows/doc/pljava || _die "Failed to install the pljava docs."
    
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

    # Setup the installer scripts. 
    mkdir -p staging/windows/installer/server || _die "Failed to create a directory for the install scripts"
    cp scripts/windows/installruntimes.vbs staging/windows/installer/installruntimes.vbs || _die "Failed to copy the installruntimes script ($WD/scripts/windows/installruntimes.vbs)"
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
	
    PG_DATETIME_SETTING=`cat staging/windows/include/pg_config.h | grep "#define USE_INTEGER_DATETIMES 1"`

    if [ "x$PG_DATETIME_SETTING" = "x" ]
    then
          PG_DATETIME_SETTING="floating-point numbers"
    else
          PG_DATETIME_SETTING="64-bit integers"
    fi

    _replace PG_DATETIME_SETTING "$PG_DATETIME_SETTING" installer.xml || _die "Failed to replace the date-time setting in the installer.xml"

	
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"
	
	# Rename the installer
	mv $WD/output/postgresql-$PG_MAJOR_VERSION-windows-installer.exe $WD/output/postgresql-$PG_PACKAGE_VERSION-windows.exe || _die "Failed to rename the installer"

    
    cd $WD
}

