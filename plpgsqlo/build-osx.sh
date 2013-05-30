#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_plpgsqlo_osx() {

    cd $WD/server/source
    # Remove any existing plpgsqlo directory that might exist, in server
    if [ -e postgres.osx/src/pl/plpgsqlo ];
    then
      echo "Removing existing plpgsqlo directory"
      rm -rf postgres.osx/src/pl/plpgsqlo || _die "Couldn't remove the existing plpgsqlo directory"
    fi

    # create a copy of the plpgsql tree
    cp -R postgresql-$PG_TARBALL_POSTGRESQL/src/pl/plpgsql postgres.osx/src/pl/plpgsqlo || _die "Failed to create copy of plpgsql tree (postgresql-$PG_TARBALL_POSTGRESQL/src/pl/plpgsql)"
    grep -irl plpgsql postgres.osx/src/pl/plpgsqlo |xargs sed -i .bak 's/\([pP][lL][pP][gG][sS][qQ][lL]\)/\1o/g'
    grep -rl PLPGSQLo_ postgres.osx/src/pl/plpgsqlo |xargs sed -i .bak 's/\(PLPGSQL\)o/\1/g'
    mv postgres.osx/src/pl/plpgsqlo/src/plpgsql.h postgres.osx/src/pl/plpgsqlo/src/plpgsqlo.h || _die "Failed to move plpgsql.h to plpgsqlo.h"
    # Copy files from pg-sources into plpgsqlo
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/backend/utils/adt/encode.c $WD/server/source/postgres.osx/src/pl/plpgsqlo/src || _die "Failed to copy encode.c"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/md5.c $WD/server/source/postgres.osx/src/pl/plpgsqlo/src || _die "Failed to copy md5.c"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/md5.h $WD/server/source/postgres.osx/src/pl/plpgsqlo/src || _die "Failed to copy md5.h"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/contrib/pgcrypto/px.h $WD/server/source/postgres.osx/src/pl/plpgsqlo/src || _die "Failed to copy px.h"
    # copy wrap.c and wrap.h in plpgsqlo. These 2 files are taken from edb sources.
    cp $WD/plpgsqlo/resources/wrap.c $WD/server/source/postgres.osx/src/pl/plpgsqlo/src || _die "Failed to copy wrap.c file for plpgsqlo obfuscation"
    cp $WD/plpgsqlo/resources/wrap.h $WD/server/source/postgres.osx/src/pl/plpgsqlo/src || _die "Failed to copy wrap.h file for plpgsqlo obfuscation"
    # Copy files from pg-sources into plpgsqlo which are required for windows build
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Project.pm $WD/server/source/postgres.osx/src/tools/msvc/. || _die "Failed to copy Project.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Mkvcbuild.pm $WD/server/source/postgres.osx/src/tools/msvc/. || _die "Failed to copy Mkvcbuild.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/pgbison.bat $WD/server/source/postgres.osx/src/tools/msvc/. || _die "Failed to copy pgbison.bat"

    cd postgres.osx
    patch -p0 < $WD/plpgsqlo/resources/plpgsqlo.patch || _die "Failed to apply patch on plpgsqlo tree (plpgsqlo.patch)"

    cd $WD/server/source
	
    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/plpgsqlo/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/plpgsqlo/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    rm -rf $PG_PATH_OSX/plpgsqlo/staging/osx/lib/plpgsqlo.so" || _die "Failed to remove plpgsqlo.so from server staging directory
    echo "Creating staging directory ($WD/plpgsqlo/staging/osx)"
    mkdir -p $WD/plpgsqlo/staging/osx/plpgsqlo || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/plpgsqlo/staging/osx || _die "Couldn't set the permissions on the staging directory"

    echo "Creating staging share directory ($WD/plpgsqlo/staging/osx/share)"
    mkdir -p $WD/plpgsqlo/staging/osx/share || _die "Couldn't create the staging share directory"
    chmod 755 $WD/plpgsqlo/staging/osx/share || _die "Couldn't set the permissions on the staging share directory"
    echo "Copying plpgsqlo.sql to staging share directory"
    cp $WD/plpgsqlo/resources/plpgsqlo.sql $WD/plpgsqlo/staging/osx/share || _die "Couldn't copy plpgsqlo.sql to staging share directory"

    echo "Creating staging doc directory ($WD/plpgsqlo/staging/osx/doc)"
    mkdir -p $WD/plpgsqlo/staging/osx/doc || _die "Couldn't create the staging doc directory"
    chmod 755 $WD/plpgsqlo/staging/osx/doc || _die "Couldn't set the permissions on the staging doc directory"
    echo "Copying readme.sqlprotect to staging doc directory"
    cp $WD/plpgsqlo/resources/README.plsecure $WD/plpgsqlo/staging/osx/doc || _die "Couldn't copy README.plsecure to staging doc directory"

}

################################################################################
# PG Build
################################################################################

_build_plpgsqlo_osx() {

    cd $PG_PATH_OSX/server/source/postgres.osx/src/pl/plpgsqlo/; make distclean ; make || _die "Failed to build plpgsqlo"
    mkdir -p $PG_PATH_OSX/plpgsqlo/staging/osx/lib || _die "Failed to create staging/osx/lib "

    rm -f $PG_PATH_OSX/plpgsqlo/staging/osx/lib/plpgsqlo.so; cp $PG_PATH_OSX/server/source/postgres.osx/src/pl/plpgsqlo/src/plpgsqlo.so $PG_PATH_OSX/plpgsqlo/staging/osx/lib/ || _die "Failed to copy plpgsqlo.so to staging directory"

    install_name_tool -change /usr/local/lib/libz.1.2.6.dylib @loader_path/../libz.1.dylib $PG_PATH_OSX/plpgsqlo/staging/osx/lib/plpgsqlo.so

}


################################################################################
# PG Build
################################################################################

_postprocess_plpgsqlo_osx() {


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
    # Restoring postgres.platform_name files which were changed by plsecure.patch
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Project.pm $WD/server/source/postgres.osx/src/tools/msvc/. || _die "Failed to copy Project.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/Mkvcbuild.pm $WD/server/source/postgres.osx/src/tools/msvc/. || _die "Failed to copy Mkvcbuild.pm"
    cp $WD/server/source/postgresql-$PG_TARBALL_POSTGRESQL/src/tools/msvc/pgbison.bat $WD/server/source/postgres.osx/src/tools/msvc/. || _die "Failed to copy pgbison.bat"

    cd $WD

}

