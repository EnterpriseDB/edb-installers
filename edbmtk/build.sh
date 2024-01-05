#!/bin/bash

# Prepared by Aqeel
source $WD/edbmtk/component_settings.sh
source $WD/edbmtk/edbmtk_branding.sh

# Read the various build scripts

# Mac OS X
if [ $EDB_ARCH_OSX = 1 ]; 
then
    source $WD/edbmtk/build-osx.sh
fi

# Linux
if [ $EDB_ARCH_LINUX = 1 ];
then
    source $WD/edbmtk/build-linux.sh
fi

# Linux x64
if [ $EDB_ARCH_LINUX_X64 = 1 ];
then
    source $WD/edbmtk/build-linux-x64.sh
fi

# Windows
if [ $EDB_ARCH_WINDOWS = 1 ];
then
    source $WD/edbmtk/build-windows.sh
fi

if [ $EDB_ARCH_WINDOWS_X64 = 1 ];
then
     source $WD/edbmtk/build-windows.sh 
fi

# Solaris-Intel
if [ $EDB_ARCH_SOLARIS_INTEL = 1 ];
then
    source $WD/edbmtk/build-solaris.sh
fi

# Solaris-Sparc
if [ $EDB_ARCH_SOLARIS_SPARC = 1 ];
then
    source $WD/edbmtk/build-solaris-sparc.sh
fi    

# HPUX
if [ $EDB_ARCH_HPUX = 1 ];
then
    source $WD/edbmtk/build-hpux.sh
fi    

################################################################################
# Build preparation
################################################################################

_prep_edbmtk() {

    # Create the source directory if required
    if [ ! -e $WD/edbmtk/source ];
    then
        mkdir $WD/edbmtk/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/edbmtk/source

    if [ ! -e EDB-MTK ];
    then
      echo "Fetching edbmtk sources from the repo..."
      mkdir -p EDB-MTK
      cd EDB-MTK
      git clone https://$TOKEN@github.com/EnterpriseDB/migration-toolkit . || _die "Failed to fetch MTK source from repository"
      git checkout $EDB_TAG_EDBMTK || _die "Failed to checkout MTK source from tag: $EDB_TAG_EDBMTK"
    else
      cd $WD/edbmtk/source/EDB-MTK
      echo "Updating edbmtk sources from the repo..."
      git branch | head -1 | grep "no branch" > /dev/null
      if [ "$?" -ne "0" ]; then
        git pull || _die "Failed to pull MTK source"
      fi
      if  [ x$EDB_TAG_EDBMTK = x ];
      then
        git checkout master || _die "Failed to checkout MTK source from master"
      else
        git checkout $EDB_TAG_EDBMTK || _die "Failed to checkout MTK source from tag: $EDB_TAG_EDBMTK"
      fi
      git branch | head -1 | grep "no branch" > /dev/null
      if [ "$?" -ne "0" ]; then
        git pull || _die "Failed to pull MTK source"
      fi
    fi

    if [ -e $WD/edbmtk/source/pgJDBC-$EDB_VERSION_PGJDBC ];
    then
       rm -rf $WD/edbmtk/source/pgJDBC-$EDB_VERSION_PGJDBC
    fi

    cd $WD/edbmtk/source
    extract_file $WD/tarballs/pgJDBC-$EDB_VERSION_PGJDBC

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $EDB_ARCH_OSX = 1 ]; 
    then
        _prep_edbmtk_osx 
    fi

    # Linux
    if [ $EDB_ARCH_LINUX = 1 ];
    then
        _prep_edbmtk_linux 
    fi

    # Linux x64
    if [ $EDB_ARCH_LINUX_X64 = 1 ];
    then
        _prep_edbmtk_linux_x64 
    fi

    # Windows
    if [ $EDB_ARCH_WINDOWS = 1 ];
    then
        _prep_edbmtk_windows 
    fi

    if [ $EDB_ARCH_WINDOWS_X64 = 1 ];
    then
        _prep_edbmtk_windows 
    fi

    # Solaris Intel
    if [ $EDB_ARCH_SOLARIS_INTEL = 1 ];
    then
        _prep_edbmtk_solaris intel 
    fi

    # Solaris Sparc
    if [ $EDB_ARCH_SOLARIS_SPARC = 1 ];
    then
        _prep_edbmtk_solaris_sparc 
    fi    

    # HPUX
    if [ $EDB_ARCH_HPUX = 1 ];
    then
        _prep_edbmtk_hpux 
    fi    
}

################################################################################
# Build edbmtk
################################################################################

_build_edbmtk() {

    # Mac OSX
    if [ $EDB_ARCH_OSX = 1 ]; 
    then
        _build_edbmtk_osx 
    fi

    # Linux 
    if [ $EDB_ARCH_LINUX = 1 ];
    then
        _build_edbmtk_linux 
    fi

    # Linux x64
    if [ $EDB_ARCH_LINUX_X64 = 1 ];
    then
       _build_edbmtk_linux_x64 
    fi

    # Windows
    if [ $EDB_ARCH_WINDOWS = 1 ];
    then
        _build_edbmtk_windows 
    fi

    if [ $EDB_ARCH_WINDOWS_X64 = 1 ];
    then
        _build_edbmtk_windows 
    fi

    # Solaris Intel
    if [ $EDB_ARCH_SOLARIS_INTEL = 1 ];
    then
        _build_edbmtk_solaris intel 
    fi

    # Solaris Sparc
    if [ $EDB_ARCH_SOLARIS_SPARC = 1 ];
    then
        _build_edbmtk_solaris_sparc 
    fi

    # HPUX
    if [ $EDB_ARCH_HPUX = 1 ];
    then
        _build_edbmtk_hpux 
    fi
}

################################################################################
# Postprocess edbmtk
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_edbmtk() {

    cd $WD/edbmtk

    rm -f staging/${EDBMTK_INSTALLER_NAME_PREFIX}_license.txt
    cp $WD/resources/license.txt staging/${EDBMTK_INSTALLER_NAME_PREFIX}_license.txt || _die "Unable to copy ${EDBMTK_INSTALLER_NAME_PREFIX}_license.txt"
    dos2unix staging/${EDBMTK_INSTALLER_NAME_PREFIX}_license.txt
    chmod 444 staging/${EDBMTK_INSTALLER_NAME_PREFIX}_license.txt || _die "Unable to change permissions for license file."

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (edbmtk/installer.xml.in)"

    _replace EDB_VERSION_EDBMTK $EDB_VERSION_EDBMTK installer.xml || _die "Failed to set the version in the installer project file (edbmtk/installer.xml)"
    _replace EDB_BUILDNUM_EDBMTK $EDB_BUILDNUM_EDBMTK installer.xml || _die "Failed to set the version in the installer project file (edbmtk/installer.xml)"
    
    #_replace JRE_VERSIONS_LIST $JRE_VERSIONS_LIST installer.xml || _die "Failed to set old jre versions list in the installer project file (edbmtk/installer.xml)"   
    _replace TARGET_JRE_VERSION $TARGET_JRE_VERSION installer.xml || _die "Failed to set the target JRE version in the installer project file (edbmtk/installer.xml)"
  
    CORE_EDBMTK_VERSION=`echo $EDB_VERSION_EDBMTK | cut -f1 -d"."` || _die "Failed to get CORE_EDBMTK_VERSION"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION installer.xml || _die "Failed to set core edbmtk version in the installer project file (edbmtk/installer.xml)"

    _replace EDBMTK_SHORT_NAME $EDBMTK_SHORT_NAME installer.xml || _die "Failed to set the edbmtk shortname in the installer project file"
    _replace EDBMTK_INSTALL_DIR $EDBMTK_INSTALL_DIR installer.xml || _die "Failed to set the edbmtk installdir in the installer project file"
    _replace EDBMTK_INSTALLER_NAME_PREFIX $EDBMTK_INSTALLER_NAME_PREFIX installer.xml || _die "Failed to set the edbmtk installer name prefix in the installer project file"
    _replace EDB_MAIN_MENU "$EDB_MAIN_MENU" installer.xml || _die "Failed to set main menu in installer.xml file."
 
    # Mac OSX
   if [ $EDB_ARCH_OSX = 1 ]; 
   then
      package_component edbmtk osx 
   fi

   # Linux
   if [ $EDB_ARCH_LINUX = 1 ];
   then
      package_component edbmtk linux 
   fi

   # Linux x64
   if [ $EDB_ARCH_LINUX_X64 = 1 ];
   then
      package_component edbmtk linux_x64 
   fi
   
   # Windows
   if [ $EDB_ARCH_WINDOWS = 1 ];
   then
     package_component edbmtk windows 
   fi

   if [ $EDB_ARCH_WINDOWS_X64 = 1 ];
   then
     package_component edbmtk windows 
   fi

   # Solaris Intel
   if [ $EDB_ARCH_SOLARIS_INTEL = 1 ];
   then
      package_component edbmtk solaris 
   fi

   # Solaris Sparc
   if [ $EDB_ARCH_SOLARIS_SPARC = 1 ];
   then
      package_component edbmtk solaris_sparc 
   fi

   # HPUX
   if [ $EDB_ARCH_HPUX = 1 ];
   then
      package_component edbmtk hpux 
   fi
}
