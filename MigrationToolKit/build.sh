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

# HPUX
if [ $PG_ARCH_HPUX = 1 ];
then
    source $WD/MigrationToolKit/build-hpux.sh
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
      echo "Fetching MigrationToolKit sources from the repo..."
      mkdir -p EDB-MTK
      cd EDB-MTK
          git clone https://github.com/EnterpriseDB/migration-toolkit.git .
          git checkout $PG_TAG_MIGRATIONTOOLKIT
    else  
      cd $WD/MigrationToolKit/source/EDB-MTK
      echo "Updating MigrationToolKit sources from the repo..."
      git reset --hard
      if  [ x$PG_TAG_MIGRATIONTOOLKIT = x ];
      then
        git checkout master
      else
        git checkout $PG_TAG_MIGRATIONTOOLKIT
      fi

      # Checking if .git/conf file refer to older git servers i.e, gitub.ox.uk / github.pn.in if yes then replace it with github.com/EnterpriseDB
      remote_url=$(git config --get remote.origin.url)
      if [[ "$remote_url" == *"uk"* || "$remote_url" == *"pn"* ]];
      then
          git remote set-url origin https://github.com/EnterpriseDB/migration-toolkit.git
      fi

      git pull

    fi

    if [ -e $WD/MigrationToolKit/source/pgJDBC-$PG_VERSION_PGJDBC ];
    then
       rm -rf $WD/MigrationToolKit/source/pgJDBC-$PG_VERSION_PGJDBC
    fi

    cd $WD/MigrationToolKit/source 
    extract_file $WD/tarballs/pgJDBC-$PG_VERSION_PGJDBC

    # Clean up the registration plus xmls
    rm -f $WD/MigrationToolKit/staging/*.xml
    
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
      echo "Comment MTK prep linux"
      # _prep_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       echo "Comment MTK prep linux-x64"
       # _prep_MigrationToolKit_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        echo "Comment MTK prep windows"
        # _prep_MigrationToolKit_windows || exit 1
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

    # HPUX
    if [ $PG_ARCH_HPUX = 1 ];
    then
        _prep_MigrationToolKit_hpux || exit 1
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
        echo "Not building MTK on linux because MTK for linux is common for both PG and PPAS."
        #_build_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        echo "Not building MTK on linux-x64 because MTK for linux-x64 is common for both PG and PPAS."
        #_build_MigrationToolKit_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        echo "Not building MTK on windows because MTK for windows is common for both PG and PPAS."
    	#_build_MigrationToolKit_windows || exit 1
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

    # HPUX
    if [ $PG_ARCH_HPUX = 1 ];
    then
        _build_MigrationToolKit_hpux || exit 1
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

    #_registration_postprocess(STAGING DIRECTORY, COMPONENT NAME, VERSION VARIABLE, INI, REGISTRY_PREFIX, REGISTRY_PREFIX_WIN, PRODUCT_DESCRIPTION, PRODUCT_VERSION)
    _registration_plus_postprocess "$WD/MigrationToolKit/staging"  "MigrationToolKit" "MigrationToolkitVersion" "/etc/postgres-reg.ini" "MigrationToolkit" "MigrationToolkit" "MigrationToolkit" "$PG_VERSION_MIGRATIONTOOLKIT"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_MigrationToolKit_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        echo "Comment MTK post process linux"
        #_postprocess_MigrationToolKit_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        echo "Comment MTK post process linux-x64"
        #_postprocess_MigrationToolKit_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        echo "Comment MTK post process windows"
        #_postprocess_MigrationToolKit_windows || exit 1
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
   
    # HPUX
#    if [ $PG_ARCH_HPUX = 1 ];
 #   then
  #      _postprocess_MigrationToolKit_hpux || exit 1
   # fi 
}
