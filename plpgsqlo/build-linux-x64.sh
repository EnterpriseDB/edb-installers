#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_plpgsqlo_linux_x64() {

    cd $WD/server/source
    # Remove any existing plpgsqlo directory that might exist, in server
    if [ -e postgres.linux-x64/src/pl/plpgsqlo ];
    then
      echo "Removing existing plpgsqlo directory"
      rm -rf postgres.linux-x64/src/pl/plpgsqlo || _die "Couldn't remove the existing plpgsqlo directory"
    fi

    # create a copy of the plpgsql tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL/src/pl/plpgsql postgres.linux-x64/src/pl/plpgsqlo || _die "Failed to create copy of plpgsql tree (postgresql-$PG_TARBALL_POSTGRESQL/src/pl/plpgsql)"
    grep -irl plpgsql postgres.linux-x64/src/pl/plpgsqlo |xargs sed -i .bak 's/\([pP][lL][pP][gG][sS][qQ][lL]\)/\1o/g'
    grep -rl PLPGSQLo_ postgres.linux-x64/src/pl/plpgsqlo |xargs sed -i .bak 's/\(PLPGSQL\)o/\1/g'
    mv postgres.linux-x64/src/pl/plpgsqlo/src/plpgsql.h postgres.linux-x64/src/pl/plpgsqlo/src/plpgsqlo.h || _die "Failed to move plpgsql.h to plpgsqlo.h"
    # Copy files from pg-sources into plpgsqlo
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/backend/utils/adt/encode.c $WD/server/source/postgres.linux-x64/src/pl/plpgsqlo/src || _die "Failed to copy encode.c"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/md5.c $WD/server/source/postgres.linux-x64/src/pl/plpgsqlo/src || _die "Failed to copy md5.c"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/md5.h $WD/server/source/postgres.linux-x64/src/pl/plpgsqlo/src || _die "Failed to copy md5.h"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/px.h $WD/server/source/postgres.linux-x64/src/pl/plpgsqlo/src || _die "Failed to copy px.h"
    # copy wrap.c and wrap.h in plpgsqlo. These 2 files are taken from edb sources.
    cp $WD/plpgsqlo/resources/wrap.c $WD/server/source/postgres.linux-x64/src/pl/plpgsqlo/src || _die "Failed to copy wrap.c file for plpgsqlo obfuscation"
    cp $WD/plpgsqlo/resources/wrap.h $WD/server/source/postgres.linux-x64/src/pl/plpgsqlo/src || _die "Failed to copy wrap.h file for plpgsqlo obfuscation"
    # Copy files from pg-sources into plpgsqlo which are required for windows build
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Project.pm $WD/server/source/postgres.linux-x64/src/tools/msvc/. || _die "Failed to copy Project.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Mkvcbuild.pm $WD/server/source/postgres.linux-x64/src/tools/msvc/. || _die "Failed to copy Mkvcbuild.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/pgbison.bat $WD/server/source/postgres.linux-x64/src/tools/msvc/. || _die "Failed to copy pgbison.bat"

    cd postgres.linux-x64
    patch -p0 < $WD/plpgsqlo/resources/plpgsqlo.patch || _die "Failed to apply patch on plpgsqlo tree (plpgsqlo.patch)"

    cd $WD/server/source

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/plpgsqlo/staging/linux-x64 ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/plpgsqlo/staging/linux-x64 || _die "Couldn't remove the existing staging directory"
    fi

    ssh $PG_SSH_LINUX_X64 "rm -rf $PG_PATH_LINUX_X64/plpgsqlo/staging/linux-x64/lib/plpgsqlo.so" || _die "Failed to remove plpgsqlo.so from server staging directory"
    echo "Creating staging directory ($WD/plpgsqlo/staging/linux-x64)"
    mkdir -p $WD/plpgsqlo/staging/linux-x64 || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/plpgsqlo/staging/linux-x64 || _die "Couldn't set the permissions on the staging directory"

    echo "Creating staging share directory ($WD/plpgsqlo/staging/linux-x64/share)"
    mkdir -p $WD/plpgsqlo/staging/linux-x64/share || _die "Couldn't create the staging share directory"
    chmod 755 $WD/plpgsqlo/staging/linux-x64/share || _die "Couldn't set the permissions on the staging share directory"
    echo "Copying plpgsqlo.sql to staging share directory"
    cp $WD/plpgsqlo/resources/plpgsqlo.sql $WD/plpgsqlo/staging/linux-x64/share || _die "Couldn't copy plpgsqlo.sql to staging share directory"

    echo "Creating staging doc directory ($WD/plpgsqlo/staging/linux-x64/doc)"
    mkdir -p $WD/plpgsqlo/staging/linux-x64/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $WD/plpgsqlo/staging/linux-x64/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying readme.sqlprotect to staging doc directory"
    cp $WD/plpgsqlo/resources/README.plsecure $WD/plpgsqlo/staging/linux-x64/doc || _die "Couldn't copy README.plsecure to staging doc directory"


}

################################################################################
# PG Build
################################################################################

_build_plpgsqlo_linux_x64() {

    # Execute configure so that Makefile.Global is created which is being used by plpgsqlo/Makefile
    ssh $PG_SSH_LINUX_X64 "cd $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/src/pl/plpgsqlo/; make clean; make " || _die "Failed to build plpgsqlo"
    ssh $PG_SSH_LINUX_X64 "mkdir -p $PG_PATH_LINUX_X64/plpgsqlo/staging/linux-x64/lib " || _die "Failed to create staging/linux-x64/lib "

    ssh $PG_SSH_LINUX_X64 "rm -f $PG_PATH_LINUX_X64/plpgsqlo/staging/linux-x64/lib/plpgsqlo.so; cp $PG_PATH_LINUX_X64/server/source/postgres.linux-x64/src/pl/plpgsqlo/src/plpgsqlo.so $PG_PATH_LINUX_X64/plpgsqlo/staging/linux-x64/lib/" || _die "Failed to copy plpgsqlo.so to staging directory"

}


################################################################################
# PG Build
################################################################################

_postprocess_plpgsqlo_linux_x64() {


    cd $WD/plpgsqlo
    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux-x64 || _die "Failed to build the installer"
    # Restoring postgres.platform_name files which were changed by plpgsqlo.patch
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Project.pm $WD/server/source/postgres.linux-x64/src/tools/msvc/. || _die "Failed to copy Project.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Mkvcbuild.pm $WD/server/source/postgres.linux-x64/src/tools/msvc/. || _die "Failed to copy Mkvcbuild.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/pgbison.bat $WD/server/source/postgres.linux-x64/src/tools/msvc/. || _die "Failed to copy pgbison.bat"

    cd $WD

}

