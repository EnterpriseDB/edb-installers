#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/MigrationToolKit/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/MigrationToolKit/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/MigrationToolKit/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/MigrationToolKit/build-windows.sh
fi
    
# Solaris x64
if [ $PG_ARCH_SOLARIS_X64 = 1 ];
then
    source $WD/MigrationToolKit/build-solaris-x64.sh
fi
    
# Solaris sparc
if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
then
    source $WD/MigrationToolKit/build-solaris-sparc.sh
fi

################################################################################
# Build preparation
################################################################################

_prep_MigrationToolKit() {

    # Create the source directory if required
    if [ ! -e $WD/MigrationToolKit/source ];
    then
        mkdir $WD/MigrationToolKit/source
    fi


    # Enter the source directory and cleanup if required
    cd $WD/MigrationToolKit/source

    if [ ! -e EDB-MTK ];
    then
      echo "Fetching MigrationToolKit sources from the cvs..."
      mkdir -p EDB-MTK
      cd EDB-MTK
      if  [ x$PG_TAG_MIGRATIONTOOLKIT = x ];
      then
          cvs -d:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-MTK co . 
      else
          cvs -d:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-MTK co -r $PG_TAG_MIGRATIONTOOLKIT . 
      fi
    else  
      cd $WD/MigrationToolKit/source/EDB-MTK
      echo "Updating MigrationToolKit sources from the cvs..."
      if  [ x$PG_TAG_MIGRATIONTOOLKIT = x ];
      then
          CVSROOT=:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-MTK cvs update -dPCA
      else
          CVSROOT=:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-MTK cvs update -r $PG_TAG_MIGRATIONTOOLKIT -dPC
      fi
    fi

    if [ -e $WD/MigrationToolKit/source/pgJDBC-$PG_VERSION_PGJDBC ];
    then
       rm -rf $WD/MigrationToolKit/source/pgJDBC-$PG_VERSION_PGJDBC
    fi

    cd $WD/MigrationToolKit/source 
    extract_file $WD/tarballs/pgJDBC-$PG_VERSION_PGJDBC
    
    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_MigrationToolKit_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_MigrationToolKit_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_MigrationToolKit_windows || exit 1
    fi
    
    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _prep_MigrationToolKit_solaris_x64 || exit 1
    fi
    
    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _prep_MigrationToolKit_solaris_sparc || exit 1
    fi

}

################################################################################
# Build MigrationToolKit
################################################################################

_build_MigrationToolKit() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_MigrationToolKit_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_MigrationToolKit_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_MigrationToolKit_windows || exit 1
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _build_MigrationToolKit_solaris_x64 || exit 1
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _build_MigrationToolKit_solaris_sparc || exit 1
    fi

}

################################################################################
# Postprocess MigrationToolKit
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_MigrationToolKit() {

    cd $WD/MigrationToolKit


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (MigrationToolKit/installer.xml.in)"

    _replace PG_VERSION_MIGRATIONTOOLKIT $PG_VERSION_MIGRATIONTOOLKIT installer.xml || _die "Failed to set the major version in the installer project file (MigrationToolKit/installer.xml)"
    _replace PG_BUILDNUM_MIGRATIONTOOLKIT $PG_BUILDNUM_MIGRATIONTOOLKIT installer.xml || _die "Failed to set the Build Number in the installer project file (MigrationToolKit/installer.xml)"

    #_registration_postprocess(STAGING DIRECTORY, COMPONENT NAME, VERSION VARIABLE, INI, REGISTRY_PREFIX, REGISTRY_PREFIX_WIN, TEMP DIRECTORY, COMONENT TYPE)
    _registration_postprocess "$WD/MigrationToolKit/staging"  "MigrationToolKit"         "MigrationToolkitVersion" "/etc/postgres-reg.ini" "MigrationToolkit" "MigrationToolkit" "mtk" "mtk"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_MigrationToolKit_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_MigrationToolKit_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _postprocess_MigrationToolKit_windows || exit 1
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _postprocess_MigrationToolKit_solaris_x64 || exit 1
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _postprocess_MigrationToolKit_solaris_sparc || exit 1
    fi
    
}
