#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ];
then
    echo "OS X not supported"
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    echo "Linux 32bit not supported"
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/hdfs_fdw/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    echo "Windows 32bit not supported"
fi

# Windows-x64
if [ $PG_ARCH_WINDOWS_X64 = 1 ];
then
    echo "Yet to add support for Win64"
    #source $WD/hdfs_fdw/build-windows-x64.sh
fi

################################################################################
# Build preparation
################################################################################

_prep_hdfs_fdw() {

    # Create the source directory if required
    if [ ! -e $WD/hdfs_fdw/source ];
    then
        mkdir $WD/hdfs_fdw/source
    fi

    cd $WD/hdfs_fdw/source

    if [ ! -e hdfs_fdw ];
    then
      echo "Cloning the hdfs_fdw sources..."
      git clone https://github.com/EnterpriseDB/hdfs_fdw hdfs_fdw || _die "Failed to set fetch HDFS_FDW source from repository"

      cd hdfs_fdw
      git checkout $PG_TAG_HDFS_FDW || _die "Failed to set checkout from tag $PG_TAG_HDFS_FDW"
      if [ -f $WD/tarballs/hdfs_fdw_rm38295.patch ]; then
          patch -p1 < ~/tarballs/hdfs_fdw_rm38295.patch
      fi
    else
      cd hdfs_fdw
    fi

    cd $WD/hdfs_fdw/source

    # Per-platform prep
    cd $WD

    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ];
    then
	echo "OS X not supported"
        #_prep_hdfs_fdw_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
	echo "Linux 32bit not supported"
        #_prep_hdfs_fdw_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_hdfs_fdw_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        echo "Windows 32bit not supported"
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        echo "Yet to add support for Win64"
       # _prep_hdfs_fdw_windows_x64 || exit 1
    fi
}

################################################################################
# Build hdfs_fdw
################################################################################

_build_hdfs_fdw() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ];
    then
	echo "OS X not supported"
        #_build_hdfs_fdw_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
	echo "Linux 32bit not supported"
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _build_hdfs_fdw_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	echo "Windows 32bit not supported"
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        echo "Yet to add support for Win64"
        #_build_hdfs_fdw_windows_x64 || exit 1
    fi
}

################################################################################
# Postprocess hdfs_fdw
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_hdfs_fdw() {
    cd $WD/hdfs_fdw/staging
    rm -f hdfs_fdw_license.txt LICENSE README.md INSTALL
    cd $WD/hdfs_fdw
    cp ./source/hdfs_fdw/LICENSE staging/hdfs_fdw_license.txt || _die "Unable to copy hdfs_fdw_license.txt"
    cp ./source/hdfs_fdw/README.md staging/README.md || _die "Unable to copy README file from source"
    cp ./source/hdfs_fdw/INSTALL staging/INSTALL || _die "Unable to copy INSTALL file from source"
    dos2unix staging/hdfs_fdw_license.txt staging/README staging/INSTALL
    chmod 444 staging/hdfs_fdw_license.txt || _die "Unable to change permissions for license file."
    chmod 444 staging/README.md staging/INSTALL || _die "Unable to change permissions for INSTALL file."


    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (hdfs_fdw/installer.xml.in)"

    PG_CURRENT_VERSION=`echo $PG_MAJOR_VERSION | sed -e 's/\.//'`

    _replace PG_VERSION_HDFS_FDW $PG_VERSION_HDFS_FDW installer.xml || _die "Failed to set the version in the installer project file (hdfs_fdw/installer.xml)"
    _replace PG_BUILDNUM_HDFS_FDW $PG_BUILDNUM_HDFS_FDW installer.xml || _die "Failed to set the version in the installer project file (hdfs_fdw/installer.xml)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the PG Major version in the installer project file (hdfs_fdw/installer.xml)"
    _replace PG_CURRENT_VERSION $PG_CURRENT_VERSION installer.xml || _die "Failed to set the PG Current Number in the installer project file (PostGIS/installer.xml)"

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ];
    then
	echo "OS X not supported"
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
	echo "Linux 32bit not supported"
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_hdfs_fdw_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
	echo "Windows 32bit not supported"
    fi

    # Windows-x64
    if [ $PG_ARCH_WINDOWS_X64 = 1 ];
    then
        echo "Yet to add support for Win64"
        #_postprocess_hdfs_fdw_windows_x64 || exit 1
    fi
}
