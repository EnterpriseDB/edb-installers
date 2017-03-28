#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_server_windows() {
    # Following echo statement for Jenkins Console Section output
    echo "BEGIN PREP Server Windows"

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
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c del /S /Q vc-build-pgadmin4.bat"
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

    if [ -f $WD/server/scripts/windows/vc-build-pgadmin4.bat ];
    then
        echo "Removing existing vc-build-pgadmin4 script"
        rm -rf $WD/server/scripts/windows/vc-build-pgadmin4.bat || _die "Couldn't remove the existing vc-build-pgadmin4 script"
    fi
    
    # Grab a copy of the source tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL postgres.windows || _die "Failed to copy the source code (source/postgres.windows)"

    cp -R pgadmin4-$PG_TARBALL_PGADMIN pgadmin.windows || _die "Failed to copy the source code (source/pgadmin.windows)"

    # We build only dynamic libs of wxWidgets which puts the hhp2cached in the vc_mswudll instead of vc_mswu.
    # Patch the builddocs.bat of pgadmin so that it finds the hhp2cached executable
    cd pgadmin.windows/docs/
    #patch -p0 < ~/tarballs/builddocs.patch

    cd $WD/server/source

    cp -R stackbuilder stackbuilder.windows || _die "Failed to copy the source code (source/stackbuilder.windows)"

    cd stackbuilder.windows
    patch -p1 < $WD/../patches/sb_patch_for_pg.patch
    cd $WD/server/source

    
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/server/staging/windows ];
    then
        echo "Removing existing staging directory"
        rm -rf $WD/server/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/server/staging/windows)"
    mkdir -p $WD/server/staging/windows || _die "Couldn't create the staging directory"

    echo "END PREP Server Windows"
}

################################################################################
# Build
################################################################################

_build_server_windows() {
    echo "BEGIN BUILD Server Windows"
    
    # Create a build script for VC++
    cd $WD/server/scripts/windows
    
    cat <<EOT > "vc-build.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86

@SET PGBUILD=$PG_PGBUILD_WINDOWS
@SET OPENSSL=$PG_PGBUILD_WINDOWS
@SET WXWIN=$PG_WXWIN_WINDOWS
@SET INCLUDE=$PG_PGBUILD_WINDOWS\\include;%INCLUDE%
@SET LIB=$PG_PGBUILD_WINDOWS\\lib;%LIB%
@SET PGDIR=$PG_PATH_WINDOWS\\output
@SET SPHINXBUILD=$PG_PYTHON_WINDOWS\\Scripts\\sphinx-build.exe

REM batch file splits single argument containing "=" sign into two
REM Following code handles this scenario

IF "%2" == "UPGRADE" GOTO upgrade
IF "%~3" == "" ( SET VAR3=""
) ELSE (
SET VAR3="%3=%4"
)
msbuild %1 /p:Configuration=%2 %VAR3%
GOTO end

:upgrade 
vcupgrade /overwrite %1

:end

EOT

cat <<EOT > "vc-build-pgadmin4.bat"
REM Setting Visual Studio Environment
CALL "$PG_VSINSTALLDIR_WINDOWS\VC\vcvarsall.bat" x86
@SET PYTHON_HOME=$PGAMIN_PYTHON_WINDOWS
@SET PYTHON_VERSION=27

cd "$PG_PATH_WINDOWS\pgadmin.windows\runtime"
$PG_QMAKE_WINDOWS
nmake

EOT

    
    # Copy in an appropriate config.pl and buildenv.pl
    cd $WD/server/source/
    cat <<EOT > "postgres.windows/src/tools/msvc/config.pl"
# Configuration arguments for msbuild.
use strict;
use warnings;

our \$config = {
    asserts=>0,                         # --enable-cassert
    integer_datetimes=>1,               # --enable-integer-datetimes
    nls=>'$PG_PGBUILD_WINDOWS',        # --enable-nls=<path>
    tcl=>'$PG_TCL_WINDOWS',            # --with-tls=<path>
    perl=>'$PG_PERL_WINDOWS',             # --with-perl
    python=>'$PG_PYTHON_WINDOWS',         # --with-python=<path>
    ldap=>1,                # --with-ldap
    openssl=>'$PG_PGBUILD_WINDOWS',     # --with-ssl=<path>
    xml=>'$PG_PGBUILD_WINDOWS',
    xslt=>'$PG_PGBUILD_WINDOWS',
    iconv=>'$PG_PGBUILD_WINDOWS',
    zlib=>'$PG_PGBUILD_WINDOWS',        # --with-zlib=<path>
    uuid=>'$PG_PGBUILD_WINDOWS\uuid'       # --with-uuid-ossp
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
\$ENV{Framework40Version} = 'v4.0';
\$ENV{FrameworkSDKDir} = '$PG_FRAMEWORKSDKDIR_WINDOWS';
\$ENV{DevEnvDir} = '$PG_DEVENVDIR_WINDOWS';
\$ENV{M4} = '$PG_PGBUILD_WINDOWS\bin\m4.exe';
\$ENV{CONFIG} = 'Release $PLATFORM_TOOLSET';

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
    '$PG_PGBUILD_WINDOWS\bin',
    \$ENV{PATH}
);
         
\$ENV{INCLUDE} = join
(
    ';',
    '$PG_VSINSTALLDIR_WINDOWS\VC\ATLMFC\INCLUDE',
    '$PG_VSINSTALLDIR_WINDOWS\VC\INCLUDE',
    '$PG_VSINSTALLDIR_WINDOWS\VC\PlatformSDK\include',
    '$PG_FRAMEWORKSDKDIR_WINDOWS\include',
    '$PG_PGBUILD_WINDOWS\include',
    \$ENV{INCLUDE}
);

\$ENV{LIB} = join
(
    ';',
    '$PG_VSINSTALLDIR_WINDOWS\VC\ATLMFC\LIB',
    '$PG_VSINSTALLDIR_WINDOWS\VC\LIB',
    '$PG_VSINSTALLDIR_WINDOWS\VC\PlatformSDK\lib',
    '$PG_FRAMEWORKSDKDIR_WINDOWS\lib',
    '$PG_PGBUILD_WINDOWS\lib',
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
        <GETTEXTPATH>$PG_PGBUILD_WINDOWS</GETTEXTPATH>
        
        <!-- OpenSSL source tree -->
        <OPENSSLPATH>$PG_PGBUILD_WINDOWS</OPENSSLPATH>
        
    </PropertyGroup>
</Project>
EOT
        
    # Zip up the scripts directories and copy them to the build host, then unzip
    cd $WD/server/scripts/windows/
    echo "Copying scripts source tree to Windows build VM"
    zip -r scripts.zip vc-build.bat vc-build-pgadmin4.bat createuser getlocales validateuser || _die "Failed to pack the scripts source tree (ms-build.bat vc-build.bat, createuser, getlocales, validateuser)"

    rsync -av scripts.zip $PG_SSH_WINDOWS:$PG_CYGWIN_PATH_WINDOWS || _die "Failed to copy the scripts source tree to the windows build host (scripts.zip)"
    ssh -v $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip -o scripts.zip" || _die "Failed to unpack the scripts source tree on the windows build host (scripts.zip)"
    
    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\createuser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat createuser.vcproj UPGRADE " || _die "Failed to build createuser on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\createuser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat createuser.vcxproj Release $PLATFORM_TOOLSET" || _die "Failed to build createuser on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\getlocales; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat getlocales.vcproj UPGRADE " || _die "Failed to build getlocales on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\getlocales; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat getlocales.vcxproj Release $PLATFORM_TOOLSET" || _die "Failed to build getlocales on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\validateuser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat validateuser.vcproj UPGRADE " || _die "Failed to build validateuser on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\validateuser; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat validateuser.vcxproj Release $PLATFORM_TOOLSET" || _die "Failed to build validateuser on the windows build host"
    
    # Move the resulting binaries into place
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\output\\\\installer\\\\server" || _die "Failed to create the server directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\createuser\\\\release\\\\createuser.exe $PG_PATH_WINDOWS\\\\output\\\\installer\\\\server" || _die "Failed to copy the createuser proglet on the windows build host" 
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\getlocales\\\\release\\\\getlocales.exe $PG_PATH_WINDOWS\\\\output\\\\installer\\\\server" || _die "Failed to copy the getlocales proglet on the windows build host" 
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\validateuser\\\\release\\\\validateuser.exe $PG_PATH_WINDOWS\\\\output\\\\installer\\\\server" || _die "Failed to copy the validateuser proglet on the windows build host" 
    
    # Zip up the source directory and copy it to the build host, then unzip
    cd $WD/server/source/
    chmod +x postgres.windows/src/tools/msvc/install.bat
    echo "Copying source tree to Windows build VM"
    rm postgres.windows/contrib/pldebugger/Makefile # Remove the unix makefile so that the build scripts don't try to parse it - we have our own.
    zip -r postgres.zip postgres.windows || _die "Failed to pack the source tree (postgres.windows)"
    rsync -av postgres.zip $PG_SSH_WINDOWS:$PG_CYGWIN_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (postgres.zip)"
    ssh -v $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip -o postgres.zip" || _die "Failed to unpack the source tree on the windows build host (postgres.zip)"
  
    PG_CYGWIN_PERL_WINDOWS=`echo $PG_PERL_WINDOWS | sed -e 's;:;;g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/cygdrive/:g'` 
    PG_CYGWIN_PYTHON_WINDOWS=`echo $PG_PYTHON_WINDOWS | sed -e 's;:;;g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/cygdrive/:g'` 
    PG_CYGWIN_TCL_WINDOWS=`echo $PG_TCL_WINDOWS | sed -e 's;:;;g' | sed -e 's:\\\\:/:g' | sed -e 's:^:/cygdrive/:g'` 

    # Build the code and install into a temporary directory
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/src/tools/msvc; export PATH=\$PATH:$PG_CYGWIN_PERL_WINDOWS/bin:$PG_CYGWIN_PYTHON_WINDOWS:$PG_CYGWIN_TCL_WINDOWS/bin; export VisualStudioVersion=12.0; ./build.bat " || _die "Failed to build postgres on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/src/tools/msvc; export PATH=\$PATH:$PG_CYGWIN_PERL_WINDOWS/bin:$PG_CYGWIN_PYTHON_WINDOWS:$PG_CYGWIN_TCL_WINDOWS/bin; ./install.bat $PG_PATH_WINDOWS\\\\output" || _die "Failed to install postgres on the windows build host"
    
    # Build the debugger plugins
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/contrib/pldebugger; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat pldebugger.proj Release" || _die "Failed to build the pldebugger plugin"
    
    # Copy the debugger plugins into place
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\postgres.windows\\\\contrib\\\\pldebugger\\\\plugin_debugger.dll $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy the debugger plugin on the windows build host"    
    
    # Copy the various support files into place
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\vcredist\\\\vcredist_x86.exe $PG_PATH_WINDOWS\\\\output\\\\installer" || _die "Failed to copy the VC++ runtimes on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\ssleay32.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (ssleay32.dd)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libeay32.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (libeay32.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libiconv-2.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (iconv.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libintl-8.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (intl.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libxml2.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (libxml2.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libxslt.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (libxslt.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\zlib1.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (zlib1.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libcurl.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (libcurl)"

    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\ssleay32.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\libeay32.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\VC\\\\libeay32MD.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\VC\\\\ssleay32MD.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\iconv.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\libintl.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\libxml2.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\libxslt.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\zlib.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\lib\\\\libcurl.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    
    # Copy the third party headers except GPL license headers
    mkdir $WD/server/staging/windows/3rdinclude/
    scp $PG_SSH_WINDOWS:$PG_PGBUILD_WINDOWS/include/*.h  $WD/server/staging/windows/3rdinclude/ || _die "Failed to copy the third party headers to $WD/server/staging/windows/3rdinclude/ )"
    find $WD/server/staging/windows/3rdinclude/ -name "*.h" -exec grep -rwl "GNU General Public License" {} \; -exec rm  {} \; || _die "Failed to remove the GPL license header files."
    scp -r $WD/server/staging/windows/3rdinclude/* $PG_SSH_WINDOWS:$PG_PATH_WINDOWS\\\\output\\\\include || _die "Failed to copy the third party headers to ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output/include)"
    rm -rf $WD/server/staging/windows/3rdinclude || _die "Failed to remove the third party headers directory"

    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\include\\\\openssl\"" || _die "Failed to create openssl directory"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\include\\\\openssl\\\\*.h $PG_PATH_WINDOWS\\\\output\\\\include\\\\openssl" || _die "Failed to copy third party headers on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\include\\\\libxml\"" || _die "Failed to create libxml directory"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\include\\\\libxml\\\\*.h $PG_PATH_WINDOWS\\\\output\\\\include\\\\libxml" || _die "Failed to copy third party headers on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\include\\\\libxslt\"" || _die "Failed to create libxslt directory"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\include\\\\libxslt\\\\*.h $PG_PATH_WINDOWS\\\\output\\\\include\\\\libxslt" || _die "Failed to copy third party headers on the windows build host"

    # Copy the wxWidgets libraries    
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxbase28u_net_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxbase28u_net_vc_custom.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxbase28u_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxbase28u_vc_custom.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxbase28u_xml_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxbase28u_xml_vc_custom.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_adv_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxmsw28u_adv_vc_custom.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_aui_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxmsw28u_aui_vc_custom.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_core_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxmsw28u_core_vc_custom.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_html_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxmsw28u_html_vc_custom.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_stc_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxmsw28u_stc_vc_custom.dll)"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_xrc_vc_custom.dll $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to copy a dependency DLL on the windows build host (wxmsw28u_xrc_vc_custom.dll)"

    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxbase28u_net.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxbase28u.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxbase28u_xml.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_adv.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_aui.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_core.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_html.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_stc.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_WXWIN_WINDOWS\\\\lib\\\\vc_dll\\\\wxmsw28u_xrc.lib $PG_PATH_WINDOWS\\\\output\\\\lib" || _die "Failed to copy a dependency lib on the windows build host"


    #####################
    # pgAdmin
    #####################
    echo "Copying pgAdmin source tree to Windows build VM"
    zip -r pgadmin.zip pgadmin.windows || _die "Failed to pack the source tree (pgadmin.windows)"
    rsync -av pgadmin.zip $PG_SSH_WINDOWS:$PG_CYGWIN_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (pgadmin.zip)"
    ssh -v $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip -o pgadmin.zip" || _die "Failed to unpack the source tree on the windows build host (pgadmin.zip)"

    #Create pgAdmin4 folder inside the output
    ssh $PG_SSH_WINDOWS "mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\"" || _die "Failed to create a pgAdmin 4 directory on the windows build host"
    ssh $PG_SSH_WINDOWS "mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to create a pgAdmin 4 directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\web; echo SERVER_MODE = False > config_distro.py; echo HELP_PATH = \'../../../docs/en_US/html/\' >> config_distro.py" || _die "Failed to copy config_distro.py on the windows build host"
    ssh $PG_SSH_WINDOWS "cp -R $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\web \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\"" || _die "Failed to copy web folder on the windows build host"


    #create virtualenv and install required components using pip and compile documents and runtime
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows; $PGAMIN_PYTHON_WINDOWS/Scripts/virtualenv.exe venv" || _die "Failed to create venv";
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows; source $PG_PATH_WINDOWS/pgadmin.windows/venv/Scripts/activate; export PATH=$PG_CYGWIN_PATH_WINDOWS/output/bin:$PG_CYGWIN_PATH_WINDOWS/output/lib:$PATH; $PG_PATH_WINDOWS/pgadmin.windows/venv/Scripts/pip install -r requirements.txt" || _die "pip install failed"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows; source $PG_PATH_WINDOWS/pgadmin.windows/venv/Scripts/activate; $PG_PATH_WINDOWS/pgadmin.windows/venv/Scripts/pip install sphinx" || _die "pip install sphinx failed"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows; $PG_PATH_WINDOWS/pgadmin.windows/venv/Scripts/sphinx-build $PG_PATH_WINDOWS/pgadmin.windows/docs/en_US \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\docs\\\\en_US\\\\html\"" || _die "Failed to compile html docs"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/pgadmin.windows; source $PG_PATH_WINDOWS/pgadmin.windows/venv/Scripts/activate; $PG_PATH_WINDOWS/pgadmin.windows/venv/Scripts/pip uninstall -y sphinx" || _die "pip uninstall sphinx failed"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c $PG_PATH_WINDOWS\\\\vc-build-pgadmin4.bat" || _die "Failed to buildi pgadmin4 on the windows build host"

    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\runtime\\\Release\\\\pgAdmin4.exe \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy a program file on the windows build host"

    #QT related libs
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\icudt54.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy icudt54.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\icuin54.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy icuin54.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\icuuc54.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy icuuc54.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Core.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Core.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Sql.dll  \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Sql.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Gui.dll  \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Gui.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Qml.dll  \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Qml.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5OpenGL.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5OpenGL.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Quick.dll  \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Quick.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Sensors.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Sensors.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Widgets.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Widgets.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5WebEngine.dll  \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5WebEngine.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Network.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Network.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Multimedia.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Multimedia.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5WebEngineCore.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5WebEngineCore.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\QtWebEngineProcess.exe \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy QtWebEngineProcess"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\opengl32sw.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy opengl32sw.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\libEGL.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy libEGL.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\libGLESv2.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy libGLESv2.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Svg.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Svg.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\d3dcompiler_47.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy d3dcompiler_47.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5WebChannel.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5WebChannel.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5Positioning.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5Positioning.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5PrintSupport.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5PrintSupport.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5WebEngineWidgets.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5WebEngineWidgets.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\bin\\\\Qt5MultimediaWidgets.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy Qt5MultimediaWidgets.dll"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\\\\platforms\"" || _die "Failed to create a directory platforms on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\\\\platforms\\\\bearer\"" || _die "Failed to create a directory bearer on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\\\\platforms\\\\qtwebengine\"" || _die "Failed to create a directory qtwebengine on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\plugins\\\\platforms\\\\qwindows.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\\\\platforms\"" || _die "Failed to copy qwindows.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\icudtl.dat \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy icudtl.dat"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\qtwebengine_resources.pak \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy qtwebengine_resources.pak"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\qtwebengine_resources_100p.pak \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy qtwebengine_resources_100p.pak"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\qtwebengine_resources_200p.pak \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy qtwebengine_resources_200p.pak"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\plugins\\\\bearer\\\\qgenericbearer.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\\\\platforms\\\\bearer\"" || _die "Failed to copy bearer"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\plugins\\\\bearer\\\\qnativewifibearer.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\\\\platforms\\\\bearer\"" || _die "Failed to copy bearer"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_QTPATH_WINDOWS\\\\plugins\\\\qtwebengine \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\\\\platforms\\\\qtwebengine\"" || _die "Failed to copy qtwebengine"
    ssh $PG_SSH_WINDOWS "cmd /c cd \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"; echo [Paths] > qt.conf; echo Plugins=plugins >> qt.conf" || _die "Failed to create qt.conf"

    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\ssleay32.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy sleay32.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libeay32.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy libeay32.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libiconv-2.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy libiconv-2.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PGBUILD_WINDOWS\\\\bin\\\\libintl-8.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy libintl-8.dll"
    ssh $PG_SSH_WINDOWS "cmd /c copy $PG_PATH_WINDOWS\\\\output\\\\bin\\\\libpq.dll \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" || _die "Failed to copy libpq.dll"

    ssh $PG_SSH_WINDOWS "cmd /c rd /S /Q $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\venv\\\\Scripts" || _die "Failed to remove the venv\scripts directory on the build host"
    ssh $PG_SSH_WINDOWS "cmd /c rd /S /Q $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\venv\\\\tcl"     || _die "Failed to remove the venv\tcl directory on the build host"
    ssh $PG_SSH_WINDOWS "cmd /c rd /S /Q $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\venv\\\\Include" || _die "Failed to remove the venv\Include directory on the build host"
    ssh $PG_SSH_WINDOWS "cmd /c del $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\venv\\\\pip-selfcheck.json" || _die "Failed to remove venn\pip-selfcheck.json on the build host"

    ssh $PG_SSH_WINDOWS "cp -R $PG_PATH_WINDOWS\\\\pgadmin.windows\\\\venv\\\\ \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\\"" || _die "Failed to copy venv folder on the windows build host"
    ssh $PG_SSH_WINDOWS "cp -R $PGAMIN_PYTHON_WINDOWS\\\\pythonw.exe \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\\venv\\\\\"" || _die "Failed to copy pythonw.exe binary on the windows build host"
    ssh $PG_SSH_WINDOWS "cp -R $PGAMIN_PYTHON_WINDOWS\\\\DLLs \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\\venv\\\\\"" || _die "Failed to copy DLLs folder on the windows build host"
    ssh $PG_SSH_WINDOWS "cp -R $PGAMIN_PYTHON_WINDOWS\\\\Lib  \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\\venv\\\\\"" || _die "Failed to copy Lib folder on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c del /Q  $PG_PATH_WINDOWS\\\\output\\\\pgAdmin\ 4\\\\venv\\\\Lib\\\\*.pyc" || _die "Failed to remove the pyc files on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c rd /S /Q $PG_PATH_WINDOWS\\\\output\\\\pgAdmin\ 4\\\\web\\\\regression" || _die "Failed to remove the regression directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cmd /c rd /S /Q $PG_PATH_WINDOWS\\\\output\\\\pgAdmin\ 4\\\\web\\\\pgadmin\\\\feature_tests" || _die "Failed to remove the feature_tests directory on the windows build host"
    ssh $PG_SSH_WINDOWS "cp $PGADMIN_PYTHON_DLL_WINDOWS  \"$PG_PATH_WINDOWS\\\\output\\\\pgAdmin 4\\\\bin\"" ||  _die "Failed to copy a dependency $PGADMIN_PYTHON_DLL_WINDOWS"

    #####################
    # StackBuilder
    #####################
    cd $WD/server/source
    echo "Copying StackBuilder source tree to Windows build VM"
    zip -r stackbuilder.zip stackbuilder.windows || _die "Failed to pack the source tree (stackbuilder.windows)"
    rsync -av stackbuilder.zip $PG_SSH_WINDOWS:$PG_CYGWIN_PATH_WINDOWS || _die "Failed to copy the source tree to the windows build host (stackbuilder.zip)"
    ssh -v $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c unzip -o stackbuilder.zip" || _die "Failed to unpack the source tree on the windows build host (stackbuilder.zip)"

    # Build the code
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/stackbuilder.windows; cmd /c cmake -D MS_VS_10=1 -D CURL_ROOT:PATH=$PG_PGBUILD_WINDOWS -D WX_ROOT_DIR=$PG_WXWIN_WINDOWS -D MSGFMT_EXECUTABLE=$PG_PGBUILD_WINDOWS\\\\bin\\\\msgfmt -D CMAKE_INSTALL_PREFIX=$PG_PATH_WINDOWS\\\\output\\\\StackBuilder -D CMAKE_CXX_FLAGS=\"/D _UNICODE /EHsc\" ." || _die "Failed to configure pgAdmin on the build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/stackbuilder.windows; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat stackbuilder.vcxproj Release $PLATFORM_TOOLSET" || _die "Failed to build stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/stackbuilder.windows; cmd /c $PG_PATH_WINDOWS\\\\vc-build.bat INSTALL.vcxproj Release $PLATFORM_TOOLSET" || _die "Failed to install stackbuilder on the build host"
    ssh $PG_SSH_WINDOWS "cmd /c mv $PG_PATH_WINDOWS\\\\output\\\\StackBuilder\\\\bin\\\\stackbuilder.exe $PG_PATH_WINDOWS\\\\output\\\\bin" || _die "Failed to relocate the stackbuilder executable on the build host"
    ssh $PG_SSH_WINDOWS "cmd /c rd $PG_PATH_WINDOWS\\\\output\\\\StackBuilder\\\\bin" || _die "Failed to remove the stackbuilder bin directory on the build host"

    # Zip up the installed code, copy it back here, and unpack.
    echo "Copying built tree to Unix host"
    ssh -v $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\output; cmd /c zip -r ..\\\\output.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output)"
    rsync -av $PG_SSH_WINDOWS:$PG_CYGWIN_PATH_WINDOWS/output.zip $WD/server/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/output.zip)"
    unzip $WD/server/staging/windows/output.zip -d $WD/server/staging/windows/ || _die "Failed to unpack the built source tree ($WD/staging/windows/output.zip)"
    rm $WD/server/staging/windows/output.zip

    # fixes #35408. In 9.5, some modules were moved from contrib to src/test/modules. They are meant for server testing
    # and should not be packaged for distribution. On Unix, the top level make does not build these, but on windows it does.
    # Hence, removing the files of these modules from the staging
    find $WD/server/staging/windows/ -type f \( -name "test_parser*" -o -name "test_shm_mq*" -o -name "test_ddl_deparse*" \
                                               -o -name "test_rls_hooks*" -o -name "worker_spi*" -o -name "dummy_seclabel*" \) -exec rm {} \;

    # sign stackbuilder
    win32_sign "stackbuilder.exe" "$WD/server/staging/windows/bin"

    # Install the PostgreSQL docs
    mkdir -p $WD/server/staging/windows/doc/postgresql/html || _die "Failed to create the doc directory"
    cd $WD/server/staging/windows/doc/postgresql/html || _die "Failed to change to the doc directory"
    cp -R $WD/server/source/postgres.windows/doc/src/sgml/html/* . || _die "Failed to copy the PostgreSQL documentation"
    
    # Copy in the plDebugger docs & SQL script
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/README.pldebugger $WD/server/staging/windows/doc
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/pldbgapi*.sql $WD/server/staging/windows/share/extension
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pldebugger/pldbgapi.control $WD/server/staging/windows/share/extension

    # Removing the tests and test directories from the Windows Package.
    cd $WD/server/staging/windows/pgAdmin\ 4/web
    find . -name "tests" -type d | xargs rm -rf
    cd $WD/server/staging/windows/pgAdmin\ 4/venv/Lib
    find . \( -name test -o -name tests \) -type d | xargs rm -rf
     
    cd $WD
    echo "END BUILD Server Windows"
}

################################################################################
# Post process
################################################################################

_postprocess_server_windows() {
    echo "BEGIN POST Server Windows"

    cd $WD/server
 
    pushd staging/windows
    generate_3rd_party_license "server"
    popd

    # Welcome doc
    cp "$WD/server/resources/installation-notes.html" "$WD/server/staging/windows/doc/" || _die "Failed to install the welcome document"
    cp "$WD/server/resources/enterprisedb.png" "$WD/server/staging/windows/doc/" || _die "Failed to install the welcome logo"

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

    # Copy installer onto the build system
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c rd /S /Q component_installers"
    ssh $PG_SSH_WINDOWS "cmd /c mkdir $PG_PATH_WINDOWS\\\\component_installers" || _die "Failed to create the component_installers directory on the windows build host"
    rsync -av $WD/output/postgresql-$PG_PACKAGE_VERSION-windows.exe $PG_SSH_WINDOWS:$PG_CYGWIN_PATH_WINDOWS/component_installers || _die "Unable to copy installers at windows build machine."
    
    cd $WD
    echo "END POST Server Windows"
}

