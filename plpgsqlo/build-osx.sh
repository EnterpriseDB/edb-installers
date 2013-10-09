#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_plpgsqlo_osx() {
    
    echo "BEGIN PREP plpgsqlo OSX"

    cd $WD/server/source

    PGSOURECEDIR=$WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL
    PGPLATFORMDIR=$WD/server/source/postgres.osx
    PLPGSQLOSTAGING=$WD/plpgsqlo/staging/osx

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
    
    echo "END PREP plpgsqlo OSX"
}

################################################################################
# PG Build
################################################################################

_build_plpgsqlo_osx() {

    echo "BEGIN BUILD plpgsqlo OSX"

    PGPLATFORMDIR=$WD/server/source/postgres.osx

    cd $PG_PATH_OSX/server/source/postgres.osx/src/pl/plpgsqlo/; make distclean ; make || _die "Failed to build plpgsqlo"
    mkdir -p $PG_PATH_OSX/plpgsqlo/staging/osx/lib || _die "Failed to create staging/osx/lib "

    rm -f $PG_PATH_OSX/plpgsqlo/staging/osx/lib/plpgsqlo.so
    cp $PG_PATH_OSX/server/source/postgres.osx/src/pl/plpgsqlo/src/plpgsqlo.so $PG_PATH_OSX/plpgsqlo/staging/osx/lib/ || _die "Failed to copy plpgsqlo.so to staging directory"

    cd $PGPLATFORMDIR
    patch -p1 -f -c -R < $WD/plpgsqlo/resources/plpgsqlo.patch
    
    echo "END BUILD plpgsqlo OSX"
}


################################################################################
# PG Build
################################################################################

_postprocess_plpgsqlo_osx() {

    echo "BEGIN POST plpgsqlo OSX"

    cd $WD/plpgsqlo

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Using own scripts for extract-only mode
    cp -f $WD/scripts/risePrivileges $WD/output/plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-osx.app/Contents/MacOS/plsecure
    chmod a+x $WD/output/plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-osx.app/Contents/MacOS/plsecure
    cp -f $WD/resources/extract_installbuilder.osx $WD/output/plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-osx.app/Contents/MacOS/installbuilder.sh
    _replace @@PROJECTNAME@@ plsecure $WD/output/plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-osx.app/Contents/MacOS/installbuilder.sh || _die "Failed to replace the Project Name placeholder in the one click installer in the installbuilder.sh script"
    chmod a+x $WD/output/plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-osx.app/Contents/MacOS/installbuilder.sh

    # Zip up the output
    cd $WD/output
    zip -r plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-osx.zip plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf plsecure-$PG_VERSION_PLPGSQLO-$PG_BUILDNUM_PLPGSQLO-osx.app/ || _die "Failed to remove the unpacked installer bundle"

    cd $WD
    
    echo "END POST plpgsqlo OSX"
}

