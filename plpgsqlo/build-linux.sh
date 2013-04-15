#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_plpgsqlo_linux() {

    cd $WD/server/source

    PGSOURECEDIR=$WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL
    PGPLATFORMDIR=$WD/server/source/postgres.linux
    PLPGSQLOSTAGING=$WD/plpgsqlo/staging/linux

    # Remove any existing plpgsqlo directory that might exist, in server
    if [ -e $PGPLATFORMDIR/src/pl/plpgsqlo ];
    then

      echo "Removing existing plpgsqlo directory"
      rm -rf $PGPLATFORMDIR/src/pl/plpgsqlo || _die "Couldn't remove the existing plpgsqlo directory"
    fi

    # create a copy of the plpgsql tree
    cp -R $PGSOURECEDIR/src/pl/plpgsql $PGPLATFORMDIR/src/pl/plpgsqlo || _die "Failed to create copy of plpgsql tree ($PGSOURECEDIR/src/pl/plpgsql)"
    grep -irl plpgsql $PGPLATFORMDIR/src/pl/plpgsqlo |xargs sed -i .bak 's/\([pP][lL][pP][gG][sS][qQ][lL]\)/\1o/g'
    grep -rl PLPGSQLo_ $PGPLATFORMDIR/src/pl/plpgsqlo |xargs sed -i .bak 's/\(PLPGSQL\)o/\1/g'
    mv $PGPLATFORMDIR/src/pl/plpgsqlo/src/plpgsql.h $PGPLATFORMDIR/src/pl/plpgsqlo/src/plpgsqlo.h || _die "Failed to move plpgsql.h to plpgsqlo.h"
    mv $PGPLATFORMDIR/src/pl/plpgsqlo/src/plpgsql.control $PGPLATFORMDIR/src/pl/plpgsqlo/src/plpgsqlo.control || _die "Failed to move plpgsql.control to plpgsqlo.control"
    # Copy files from pg-sources into plpgsqlo
    cp $PGSOURECEDIR/src/backend/utils/adt/encode.c $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy encode.c"
    cp $PGSOURECEDIR/contrib/pgcrypto/md5.c $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy md5.c"
    cp $PGSOURECEDIR/contrib/pgcrypto/md5.h $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy md5.h"
    cp $PGSOURECEDIR/contrib/pgcrypto/px.h $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy px.h"
    # copy wrap.c and wrap.h in plpgsqlo. These 2 files are taken from edb sources.
    cp $WD/plpgsqlo/resources/wrap.c $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy wrap.c file for plpgsqlo obfuscation"
    cp $WD/plpgsqlo/resources/wrap.h $PGPLATFORMDIR/src/pl/plpgsqlo/src || _die "Failed to copy wrap.h file for plpgsqlo obfuscation"
    # Copy files from pg-sources into plpgsqlo which are required for windows build
    cp $PGSOURECEDIR/src/tools/msvc/Project.pm   $PGPLATFORMDIR/src/tools/msvc/. || _die "Failed to copy Project.pm"
    cp $PGSOURECEDIR/src/tools/msvc/Mkvcbuild.pm $PGPLATFORMDIR/src/tools/msvc/. || _die "Failed to copy Mkvcbuild.pm"
    cp $PGSOURECEDIR/src/tools/msvc/pgbison.bat  $PGPLATFORMDIR/src/tools/msvc/. || _die "Failed to copy pgbison.bat"

    cd $PGPLATFORMDIR
    patch -p1 < $WD/plpgsqlo/resources/plpgsqlo.patch || _die "Failed to apply patch on plpgsqlo tree (plpgsqlo.patch)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $PLPGSQLOSTAGING ];
    then
      echo "Removing existing staging directory"
      rm -rf $PLPGSQLOSTAGING || _die "Couldn't remove the existing staging directory ($PLPGSQLOSTAGING)"
    fi

    echo "Creating staging directory ($PLPGSQLOSTAGING)"
    mkdir -p $PLPGSQLOSTAGING || _die "Couldn't create the staging directory"
    chmod ugo+w $PLPGSQLOSTAGING || _die "Couldn't set the permissions on the staging directory"

    echo "Creating staging share directory ($PLPGSQLOSTAGING/share)"
    mkdir -p $PLPGSQLOSTAGING/share || _die "Couldn't create the staging share directory"
    chmod 755 $PLPGSQLOSTAGING/share || _die "Couldn't set the permissions on the staging share directory"
    echo "Copying plpgsqlo.sql to staging share directory"
    cp $WD/plpgsqlo/resources/plpgsqlo.sql $PLPGSQLOSTAGING/share/ || _die "Couldn't copy plpgsqlo.sql to staging share directory"

    echo "Creating staging doc directory ($PLPGSQLOSTAGING/doc)"
    mkdir -p $PLPGSQLOSTAGING/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $PLPGSQLOSTAGING/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying readme.sqlprotect to staging doc directory"
    cp $WD/plpgsqlo/resources/README.plsecure $PLPGSQLOSTAGING/doc/ || _die "Couldn't copy README.plsecure to staging doc directory"

}

################################################################################
# plsecure Build
################################################################################

_build_plpgsqlo_linux() {

    PGBUILDSSH=$PG_SSH_LINUX
    PGSERVERREMOTEPATH=$PG_PATH_LINUX/server/source/postgres.linux
    PGREMOTESTAGINGPATH=$PG_PATH_LINUX/plpgsqlo/staging/linux
    PGPLATFORMDIR=$WD/server/source/postgres.linux

    ssh $PGBUILDSSH "cd $PGSERVERREMOTEPATH/src/pl/plpgsqlo/; make clean ; make " || _die "Failed to build plpgsqlo"
    ssh $PGBUILDSSH "mkdir -p $PGREMOTESTAGINGPATH/lib " || _die "Failed to create staging lib directory"

    ssh $PGBUILDSSH "rm -f $PGREMOTESTAGINGPATH/lib/plpgsqlo.so; cp $PGSERVERREMOTEPATH/src/pl/plpgsqlo/src/plpgsqlo.so $PGREMOTESTAGINGPATH/lib/" || _die "Failed to copy plpgsqlo.so to staging directory"

    cd $PGPLATFORMDIR
    patch -p1 -f -c -R < $WD/plpgsqlo/resources/plpgsqlo.patch
}


################################################################################
# PG Build
################################################################################

_postprocess_plpgsqlo_linux() {

    cd $WD/plpgsqlo

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml linux || _die "Failed to build the installer"

    cd $WD

}

