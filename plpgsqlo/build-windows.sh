#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_plpgsqlo_windows() {

    cd $WD/server/source
    # Remove any existing plpgsqlo directory that might exist, in server
    if [ -e postgres.windows/src/pl/plpgsqlo ];
    then
      echo "Removing existing plpgsqlo directory"
      rm -rf postgres.windows/src/pl/plpgsqlo || _die "Couldn't remove the existing plpgsqlo directory"
    fi

    # create a copy of the plpgsql tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL/src/pl/plpgsql postgres.windows/src/pl/plpgsqlo || _die "Failed to create copy of plpgsql tree (postgresql-$PG_TARBALL_POSTGRESQL/src/pl/plpgsql)"
    grep -irl plpgsql postgres.windows/src/pl/plpgsqlo |xargs sed -i .bak 's/\([pP][lL][pP][gG][sS][qQ][lL]\)/\1o/g'
    grep -rl PLPGSQLo_ postgres.windows/src/pl/plpgsqlo |xargs sed -i .bak 's/\(PLPGSQL\)o/\1/g'
    mv postgres.windows/src/pl/plpgsqlo/src/plpgsql.h postgres.windows/src/pl/plpgsqlo/src/plpgsqlo.h || _die "Failed to move plpgsql.h to plpgsqlo.h"
    # Copy files from pg-sources into plpgsqlo
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/backend/utils/adt/encode.c $WD/server/source/postgres.windows/src/pl/plpgsqlo/src || _die "Failed to copy encode.c"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/md5.c $WD/server/source/postgres.windows/src/pl/plpgsqlo/src || _die "Failed to copy md5.c"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/md5.h $WD/server/source/postgres.windows/src/pl/plpgsqlo/src || _die "Failed to copy md5.h"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/px.h $WD/server/source/postgres.windows/src/pl/plpgsqlo/src || _die "Failed to copy px.h"
    # copy wrap.c and wrap.h in plpgsqlo. These 2 files are taken from edb sources.
    cp $WD/plpgsqlo/resources/wrap.c $WD/server/source/postgres.windows/src/pl/plpgsqlo/src || _die "Failed to copy wrap.c file for plpgsqlo obfuscation"
    cp $WD/plpgsqlo/resources/wrap.h $WD/server/source/postgres.windows/src/pl/plpgsqlo/src || _die "Failed to copy wrap.h file for plpgsqlo obfuscation"
    # Copy files from pg-sources into plpgsqlo which are required for windows build
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Project.pm $WD/server/source/postgres.windows/src/tools/msvc/. || _die "Failed to copy Project.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Mkvcbuild.pm $WD/server/source/postgres.windows/src/tools/msvc/. || _die "Failed to copy Mkvcbuild.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/pgbison.bat $WD/server/source/postgres.windows/src/tools/msvc/. || _die "Failed to copy pgbison.bat"

    cd postgres.windows
    patch -p0 < $WD/plpgsqlo/resources/plpgsqlo.patch || _die "Failed to apply patch on plpgsqlo tree (plpgsqlo.patch)"

    cd $WD/server/source
    chmod -R ugo+w postgres.windows || _die "Couldn't set the permissions on the source directory"

    echo "Archieving plpgsqlo sources"
    zip -r plpgsqlo.zip postgres.windows/src/pl/plpgsqlo || _die "Couldn't create archieve of the plpgsqlo sources (plpgsqlo.zip)"
    chmod -R ugo+w postgres.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/plpgsqlo/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/plpgsqlo/staging/windows || _die "Couldn't remove the existing staging directory"
    fi
    mkdir $WD/plpgsqlo/staging/windows || _die "Couldn't create staging directory for windows"

    echo "Creating staging share directory ($WD/plpgsqlo/staging/windows/share)"
    mkdir -p $WD/plpgsqlo/staging/windows/share || _die "Couldn't create the staging share directory"
    chmod ugo+w $WD/plpgsqlo/staging/windows/share || _die "Couldn't set the permissions on the staging share directory"
    echo "Copying plpgsqlo.sql to staging share directory"
    cp $WD/plpgsqlo/resources/plpgsqlo.sql $WD/plpgsqlo/staging/windows/share || _die "Couldn't copy plpgsqlo.sql to staging share directory"

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST plpgsqlo.zip del /S /Q plpgsqlo.zip" || _die "Couldn't remove the $PG_PATH_WINDOWS\\plpgsqlo.zip on Windows VM"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c if EXIST plpgsqlo.staging rd /S /Q plpgsqlo.staging" || _die "Couldn't remove the $PG_PATH_WINDOWS\\plpgsqlo.staging directory on Windows VM"

    # Removing plpgsqlo if it already exists
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/src/pl; cmd /c if EXIST plpgsqlo del /S /Q plpgsqlo" || _die "Couldn't remove plpgsqlo on windows VM (plpgsqlo)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/release; cmd /c if EXIST plpgsqlo del /S /Q plpgsqlo" || _die "Couldn't remove plpgsqlo on windows VM (plpgsqlo)"
    # Copy sources on windows VM
    echo "Copying plpgsqlo sources to Windows VM"
    scp plpgsqlo.zip $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Couldn't copy the plpgsqlo archieve to windows VM (plpgsqlo.zip)"
    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; cmd /c  unzip plpgsqlo.zip" || _die "Couldn't extract postgresql archieve on windows VM (plpgsqlo.zip)"
    scp $WD/server/source/postgres.windows/src/tools/msvc/Mkvcbuild.pm $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgres.windows/src/tools/msvc || _die "Couldn't copy the Mkvcbuild.pm to windows VM (Mkvcbuild.pm)"
    scp $WD/server/source/postgres.windows/src/tools/msvc/Project.pm $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgres.windows/src/tools/msvc || _die "Couldn't copy the Project.pm to windows VM (Project.pm)"
    scp $WD/server/source/postgres.windows/src/tools/msvc/pgbison.bat $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/postgres.windows/src/tools/msvc || _die "Couldn't copy the pgbison.bat to windows VM (pgbison.bat)"
    
}

################################################################################
# PG Build
################################################################################

_build_plpgsqlo_windows() {

    ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS/postgres.windows/src/tools/msvc; ./build.bat RELEASE" || _die "could not build plpgsqlo on windows vm"

   # We need to copy shared objects to staging directory
   ssh $PG_SSH_WINDOWS "mkdir -p $PG_PATH_WINDOWS/plpgsqlo.staging/lib" || _die "Failed to create the lib directory"
   ssh $PG_SSH_WINDOWS "cp $PG_PATH_WINDOWS/postgres.windows/release/plpgsqlo/plpgsqlo.dll $PG_PATH_WINDOWS/plpgsqlo.staging/lib" || _die "Failed to copy plpgsqlo.dll to staging directory"

   # Zip up the installed code, copy it back here, and unpack.
   echo "Copying plpgsqlo build tree to Unix host"
   ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS\\\\plpgsqlo.staging; cmd /c zip -r ..\\\\plpgsqlo-staging.zip *" || _die "Failed to pack the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/plpgsqlo.staging)"
   scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/plpgsqlo-staging.zip $WD/plpgsqlo/staging/windows || _die "Failed to copy the built source tree ($PG_SSH_WINDOWS:$PG_PATH_WINDOWS/plpgsqlo-staging.zip)"
   unzip $WD/plpgsqlo/staging/windows/plpgsqlo-staging.zip -d $WD/plpgsqlo/staging/windows || _die "Failed to unpack the built source tree ($WD/staging/windows/plpgsqlo-staging.zip)"
   rm $WD/plpgsqlo/staging/windows/plpgsqlo-staging.zip

}



################################################################################
# PG Build
################################################################################

_postprocess_plpgsqlo_windows() {


    cd $WD/plpgsqlo

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "plpgsqlo-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-windows.exe"
    
    # Restoring postgres.platform_name files which were changed by plpgsqlo.patch
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Project.pm $WD/server/source/postgres.windows/src/tools/msvc/. || _die "Failed to copy Project.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Mkvcbuild.pm $WD/server/source/postgres.windows/src/tools/msvc/. || _die "Failed to copy Mkvcbuild.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/pgbison.bat $WD/server/source/postgres.windows/src/tools/msvc/. || _die "Failed to copy pgbison.bat"
	
    cd $WD

}

