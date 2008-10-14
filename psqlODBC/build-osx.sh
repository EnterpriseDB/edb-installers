#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_psqlODBC_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/psqlODBC/source

    if [ -e psqlODBC.osx ];
    then
      echo "Removing existing psqlODBC.osx source directory"
      rm -rf psqlODBC.osx  || _die "Couldn't remove the existing psqlODBC.osx source directory (source/psqlODBC.osx)"
    fi
   
    echo "Creating source directory ($WD/psqlODBC/source/psqlODBC.osx)"
    mkdir -p $WD/psqlODBC/source/psqlODBC.osx || _die "Couldn't create the psqlODBC.osx directory"

    # Grab a copy of the source tree
    cp -R psqlodbc-$PG_VERSION_PSQLODBC/* psqlODBC.osx || _die "Failed to copy the source code (source/psqlODBC-$PG_VERSION_PSQLODBC)"

    # Grab a copy of the docs 
    cp -R templates psqlODBC.osx || _die "Failed to copy the source code (source/templates)"

    chmod -R ugo+w psqlODBC.osx || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/psqlODBC/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/psqlODBC/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/psqlODBC/staging/osx)"
    mkdir -p $WD/psqlODBC/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/psqlODBC/staging/osx || _die "Couldn't set the permissions on the staging directory"
    
}

################################################################################
# PG Build
################################################################################

_build_psqlODBC_osx() {


    PG_STAGING=$PG_PATH_OSX/psqlODBC/staging/osx
    SOURCE_DIR=$PG_PATH_OSX/psqlODBC/source/psqlODBC.osx
    cd $SOURCE_DIR

    echo "Configuring psqlODBC sources for intel"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch i386" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --with-iodbc --prefix="$PG_STAGING" || _die "Could not configuring psqlODBC sources for intel"

    mv config.h config_i386.h

    echo "Configuring psqlODBC sources for ppc"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --with-iodbc --prefix="$PG_STAGING" || _die "Could not configuring psqlODBC sources for ppc"

    mv config.h config_ppc.h

    echo "Configuring psqlODBC sources for Universal"
    CFLAGS="$PG_ARCH_OSX_CFLAGS -arch ppc -arch i386" LDFLAGS="-lssl" PATH="$PG_PGHOME_OSX/bin:$PATH" ./configure --disable-dependency-tracking --with-iodbc --prefix="$PG_STAGING" || _die "Could not configuring psqlODBC sources for Universal"

    # Create a replacement config.h's that will pull in the appropriate architecture-specific one:
    echo "#ifdef __BIG_ENDIAN__" > config.h
    echo "#include \"config_ppc.h\"" >> config.h
    echo "#else" >> config.h
    echo "#include \"config_i386.h\"" >> config.h
    echo "#endif" >> config.h

    
    echo "Compiling psqlODBC"
    make || _die "Couldn't compile sources"

    echo "Installing psqlODBC into the sources"
    make install || _die "Couldn't install psqlODBC"

    mkdir $PG_STAGING/docs || _die "Failed to create the docs directory"
    mkdir $PG_STAGING/templates || _die "Failed to create the template directory"

    cp -R docs/* $PG_STAGING/docs  || _die "Failed to copy the docs directory to staging directory"
    cp -R templates/* $PG_STAGING/templates  || _die "Failed to copy the templates directory to staging directory"

    # Rewrite shared library references (assumes that we only ever reference libraries in lib/)
    cp -R $PG_PGHOME_OSX/lib/libpq.*dylib $PG_STAGING/lib || _die "Failed to copy the dependency library"
    _rewrite_so_refs $WD/psqlODBC/staging/osx lib @loader_path/..

}


################################################################################
# PG Build
################################################################################

_postprocess_psqlODBC_osx() {

    cd $WD/psqlODBC

    # Setup the installer scripts.
    mkdir -p staging/osx/installer/psqlODBC || _die "Failed to create a directory for the install scripts"
    
    cp scripts/osx/createshortcuts.sh staging/osx/installer/psqlODBC/createshortcuts.sh || _die "Failed to copy the createshortcuts.sh script (scripts/osx/createshortcuts.sh)"
    chmod ugo+x staging/osx/installer/psqlODBC/createshortcuts.sh

    cp scripts/osx/getodbcinstpath.sh staging/osx/installer/psqlODBC/getodbcinstpath.sh || _die "Failed to copy the getodbcinstpath.sh script (scripts/osx/getodbcinstpath.sh)"
    chmod ugo+x staging/osx/installer/psqlODBC/getodbcinstpath.sh

    cp scripts/osx/configurepsqlODBC.sh staging/osx/installer/psqlODBC/configurepsqlODBC.sh || _die "Failed to copy the configurepsqlODBC.sh script (scripts/osx/configurepsqlODBC.sh)"
    chmod ugo+x staging/osx/installer/psqlODBC/configurepsqlODBC.sh

    #Setup the launch scripts
    mkdir -p staging/osx/scripts || _die "Failed to create a directory for the launch scripts"
    cp scripts/osx/enterprisedb-launchOdbcDocs.applescript.in staging/osx/scripts/enterprisedb-launchOdbcDocs.applescript || _die "Failed to copy the enterprisedb-launchOdbcDocs.applescript.in script (scripts/osx/scripts/enterprisedb-launchOdbcDocs.applescript)"

    # Copy in the menu pick images
    mkdir -p staging/osx/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/enterprisedb-launchOdbcDocs.icns staging/osx/scripts/images || _die "Failed to copy the menu pick images (resources/enterprisedb-launchOdbcDocs.icns)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"
 
    # Zip up the output
    cd $WD/output
    zip -r psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.zip psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/ || _die "Failed to zip the installer bundle"
    rm -rf psqlodbc-$PG_VERSION_PSQLODBC-$PG_BUILDNUM_PSQLODBC-osx.app/ || _die "Failed to remove the unpacked installer bundle"
  
    cd $WD
}

