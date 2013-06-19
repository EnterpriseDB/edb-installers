#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_Slony_osx() {
      
    # Enter the source directory and cleanup if required
    cd $WD/Slony/source

    if [ -e slony.osx ];
    then
      echo "Removing existing slony.osx source directory"
      rm -rf slony.osx  || _die "Couldn't remove the existing slony.osx source directory (source/slony.osx)"
    fi

    echo "Creating slony source directory ($WD/Slony/source/slony.osx)"
    mkdir -p slony.osx || _die "Couldn't create the slony.osx directory"
    chmod ugo+w slony.osx || _die "Couldn't set the permissions on the source directory"

    # Grab a copy of the slony source tree
    cp -R slony1-$PG_VERSION_SLONY/* slony.osx || _die "Failed to copy the source code (source/slony1-$PG_VERSION_SLONY)"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/Slony/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/Slony/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/Slony/staging/osx)"
    mkdir -p $WD/Slony/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/Slony/staging/osx || _die "Couldn't set the permissions on the staging directory"

    echo "Removing existing slony files from the PostgreSQL directory"
    cd $PG_PGHOME_OSX
    rm -f bin/slon bin/slonik bin/slony_logshipper lib/postgresql/slony_funcs.so lib/postgresql/xxid.so"  || _die "Failed to remove slony binary files"
    rm -f share/postgresql/slony*.sql && rm -f share/postgresql/xxid*.sql"  || _die "remove slony share files"
}


################################################################################
# Slony Build
################################################################################

_build_Slony_osx() {

    # build slony
    PG_STAGING=$PG_PATH_OSX/Slony/staging/osx

    echo "Configuring the slony source tree"
    cd $PG_PATH_OSX/Slony/source/slony.osx/

    cp $PG_PGHOME_OSX/lib/libpq* .

    #Use cached libpq and other libraries.
    PG_PGHOME_OSX=$WD/server/caching/osx

    echo "Configuring the slony source tree for intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin  || _die "Failed to configure slony for intel"

    mv config.h config_i386.h 

    echo "Configuring the slony source tree for ppc"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin  || _die "Failed to configure slony for ppc"

   mv config.h config_ppc.h 

    echo "Configuring the slony source tree for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --prefix=$PG_PGHOME_OSX --with-pgconfigdir=$PG_PGHOME_OSX/bin  || _die "Failed to configure slony for Universal"

    # Create a replacement config.h's that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > config.h
    echo "#include \"config_ppc.h\"" >> config.h
    echo "#else" >> config.h
    echo "#include \"config_i386.h\"" >> config.h
    echo "#endif" >> config.h

    echo "Building slony"
    cd $PG_PATH_OSX/Slony/source/slony.osx
    make || _die "Failed to build slony"

    echo "Hacking xxid.so & slony1_funcs.so as it bundles only i386 version on Intel machine"
    if [ -e $PG_PATH_OSX/Slony/source/slony.osx/src/xxid ]; then
        cd $PG_PATH_OSX/Slony/source/slony.osx/src/xxid
        if [ -e xxid.so ]; then
            echo "Removing existing xxid.so"
            rm -f xxid.so || _die "Couldn't remove xxid.so"
        fi
        if [ -e xxid.o ]; then
            echo "Recreate xxid.so with both i386 & ppc architecture"
            gcc $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 -bundle -o xxid.so xxid.o -bundle_loader $PG_PGHOME_OSX/bin/postgres || _die "Couldn't create the hacked xxid.so"
        fi
    fi
    if [ -e $PG_PATH_OSX/Slony/source/slony.osx/src/backend ]; then
        cd $PG_PATH_OSX/Slony/source/slony.osx/src/backend
        if [ -e slony1_funcs.so ]; then
            echo "Removing existing slony1_funcs.so"
            rm -f slony1_funcs.so || _die "Couldn't remove slony_funcs.so"
        fi
        if [ -e slony1_funcs.o ]; then
            echo "Recreate slony1_funcs.so for both i386 & ppc architecture"
            gcc $PG_ARCH_OSX_CFLAGS -arch ppc -arch i386 -bundle -o slony1_funcs.so slony1_funcs.o -bundle_loader $PG_PGHOME_OSX/bin/postgres || _die "Couldn't create the hacked slony1_funcs.so"
        fi
    fi

 
    cd $PG_PATH_OSX/Slony/source/slony.osx
    make install || _die "Failed to install slony"

    # Slony installs it's files into postgresql directory
    # We need to copy them to staging directory

    mkdir -p $WD/Slony/staging/osx/bin
    cp $PG_PGHOME_OSX/bin/slon $PG_STAGING/bin || _die "Failed to copy slon binary to staging directory"
    cp $PG_PGHOME_OSX/bin/slonik $PG_STAGING/bin || _die "Failed to copy slonik binary to staging directory"
    cp $PG_PGHOME_OSX/bin/slony_logshipper $PG_STAGING/bin || _die "Failed to copy slony_logshipper binary to staging directory"

    mkdir -p $WD/Slony/staging/osx/lib
    cp $PG_PGHOME_OSX/lib/postgresql/slony1_funcs.so $PG_STAGING/lib || _die "Failed to copy slony_funcs.so to staging directory"
    cp $PG_PGHOME_OSX/lib/postgresql/xxid.so $PG_STAGING/lib || _die "Failed to copy xxid.so to staging directory"

    mkdir -p $WD/Slony/staging/osx/Slony
    cp $PG_PGHOME_OSX/share/postgresql/slony*.sql $PG_STAGING/Slony || _die "Failed to share files to staging directory"
    cp $PG_PGHOME_OSX/share/postgresql/xxid.*.sql $PG_STAGING/Slony || _die "Failed to share files to staging directory"

    install_name_tool -change "$WD/server/staging/osx/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" $WD/Slony/staging/osx/bin/slon
    install_name_tool -change "$WD/server/staging/osx/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" $WD/Slony/staging/osx/bin/slonik
    install_name_tool -change "$WD/server/staging/osx/lib/libpq.5.dylib" "@loader_path/../lib/libpq.5.dylib" $WD/Slony/staging/osx/bin/slony_logshipper

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    _rewrite_so_refs $WD/Slony/staging/osx lib @loader_path/..
    _rewrite_so_refs $WD/Slony/staging/osx bin @loader_path/..


}


################################################################################
# Slony Postprocess
################################################################################

_postprocess_Slony_osx() {

    PG_STAGING=$PG_PATH_OSX/Slony/staging/osx

    cd $WD/Slony

    mkdir -p staging/osx/installer/Slony || _die "Failed to create a directory for the install scripts"
    cp scripts/osx/createshortcuts.sh staging/osx/installer/Slony/createshortcuts.sh || _die "Failed to copy the createshortcuts script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/Slony/createshortcuts.sh

    cp scripts/osx/check-pgversion.sh staging/osx/installer/Slony/check-pgversion.sh || _die "Failed to copy the check-pgversion script (scripts/osx/check-pgversion.sh)"
    chmod ugo+x staging/osx/installer/Slony/check-pgversion.sh

    cp scripts/osx/configureslony.sh staging/osx/installer/Slony/configureslony.sh || _die "Failed to copy the configureSlony script (scripts/osx/configureslony.sh)"
    chmod ugo+x staging/osx/installer/Slony/configureslony.sh

    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp -R scripts/osx/pg-launchSlonyDocs.applescript.in staging/osx/scripts/pg-launchSlonyDocs.applescript || _die "Failed to copy the launch script (scripts/osx/pg-launchSlonyDocs.applescript.in)"

    # Copy in the menu pick images and XDG items
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/pg-launchSlonyDocs.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/pg-launchSlonyDocs.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output
	PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`
    zip -r slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.zip slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf slony-pg$PG_CURRENT_VERSION-$PG_VERSION_SLONY-$PG_BUILDNUM_SLONY-osx.app/ || _die "Failed to remove the unpacked installer bundle"
 
    
    cd $WD
}

