#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/pphq/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/pphq/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/pphq/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/pphq/build-windows.sh
fi
    
################################################################################
# Build preparation
################################################################################

_prep_pphq() {

    # Create the source directory if required
    if [ ! -e $WD/pphq/source ];
    then
        mkdir $WD/pphq/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/pphq/source

    # pphq
    if [ -d hq ];
    then
        echo "Removing existing hyperic directory..."
        rm -rf hq || _die "Couldn't remove the existing hyperic source directory (source/hq)"
    fi

    echo "Extracting hyperic source ..."
    extract_file ${WD}/tarballs/hyperic-hq-src-${PG_VERSION_PPHQ} || _die "Error extracting hyperic source..."

    if [ ! -d jboss-${PPHQ_JBOSS_VERSION} ];
    then
      echo "Extracting jboss binaries..."
      extract_file ${WD}/tarballs/jboss-${PPHQ_JBOSS_VERSION} || _die "Error extracting jboss binaries for pphq..."
    fi

    if [ -f ${WD}/pphq/patches/pphq-${PG_VERSION_PPHQ}-rebranding.patch ];
    then
      echo "Applying PPHQ Rebrading patch..."
      cd $WD/pphq/source/hq
      patch -p1 < ${WD}/pphq/patches/pphq-${PG_VERSION_PPHQ}-rebranding.patch
    else
      _die "PPHQ (${PG_VERSION_PPHQ}) Rebranding patch could not be found..."
    fi

    if [ -f ${WD}/pphq/patches/pphq-${PG_VERSION_PPHQ}-PG_8.4.patch ];
    then
      echo "Applying PPHQ PostgreSQL 8.4 auto-discovry patch..."
      cd $WD/pphq/source/hq
      patch -p1 < ${WD}/pphq/patches/pphq-${PG_VERSION_PPHQ}-PG_8.4.patch
    else
      _die "PPHQ PostgreSQL 8.4 auto-discovery patch could not be found"
    fi

    if [ -f ${WD}/tarballs/pphq-${PG_VERSION_PPHQ}-installer.patch ];
    then
      echo "Applying PPHQ Installer patches ..."
      cd $WD/pphq/source/hq
      patch -p1 < ${WD}/tarballs/pphq-${PG_VERSION_PPHQ}-installer.patch
    else
      _die "Installer patch for PPHQ(${PG_VERSION_PPHQ}) could not be found"
    fi

    cd $WD/pphq/source
    if [ -f ${WD}/pphq/patches/pphq_console_banner_bg.png ];
    then
      echo "Extracting PPHQ Console banner back ground image..."
      cp ${WD}/pphq/patches/pphq_console_banner_bg.png $WD/pphq/source/hq/web/images/4.0/backgrounds/hdbg.png
    fi
   
    if [ -f ${WD}/pphq/patches/pphq_logo.jpg ];
    then
      echo "Extracting PPHQ Console logo image..."
      cp ${WD}/pphq/patches/pphq_logo.jpg $WD/pphq/source/hq/web/images/4.0/logos/pphq_logo.jpg
    fi

    mv $WD/pphq/source/hq/hq_bin/launcher_bin/hq-server.exe $WD/pphq/source/hq/hq_bin/launcher_bin/pphq-server.exe || _die "Couldn't rename hq-server.exe"
    mv $WD/pphq/source/hq/hq_bin/launcher_bin/hq-agent.exe $WD/pphq/source/hq/hq_bin/launcher_bin/pphq-agent.exe || _die "Couldn't rename hq-agent.exe"

    cd $WD/pphq/source
    if [ -f build_pphq.sh ];
    then
      rm -f build_pphq.sh
    fi

    # Per-platform prep
    cd $WD
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_pphq_osx || exit 1
    fi

    cd $WD
    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_pphq_linux || exit 1
    fi

    cd $WD
    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_pphq_linux_x64 || exit 1
    fi

    cd $WD
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_pphq_windows || exit 1
    fi
    
    cd $WD
}

################################################################################
# Build pphq
################################################################################

_build_pphq() {

    cd $WD/pphq/source
    cat <<EOT >build_pphq.sh
#!/bin/bash
export JAVA_HOME=${PG_JAVA_HOME_OSX}
export ANT_HOME=${PG_ANT_HOME_OSX}
export JBOSS_HOME=${PWD}/jboss-${PPHQ_JBOSS_VERSION}
export ANT_OPTS="-Xmx256M -XX:MaxPermSize=128m"
export JAVA_OPTS="-ea"

cd hq
\${ANT_HOME}/bin/ant -Djboss.zip=${WD}/tarballs/jboss-${PPHQ_JBOSS_VERSION}.zip -Dant.bz2=${WD}/tarballs/apache-ant-${PPHQ_ANT_VERSION}-bin.tar.bz2 archive-prep
exit $?

EOT
    echo "Building PPHQ..."
    /bin/bash build_pphq.sh || _die "Error building PPHQ from souce..."

    cd $WD
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_pphq_osx || exit 1
    fi

    cd $WD
    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_pphq_linux || exit 1
    fi

    cd $WD
    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_pphq_linux_x64 || exit 1
    fi

    cd $WD
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_pphq_windows || exit 1
    fi

    cd $WD
}

################################################################################
# Postprocess pphq
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_pphq() {

    cd $WD/pphq

    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (pphq/installer.xml.in)"
    
    _replace PG_VERSION_PPHQ $PG_VERSION_PPHQ installer.xml || _die "Failed to set the version in the installer project file (pphq/installer.xml)"
    _replace PG_BUILDNUM_PPHQ $PG_BUILDNUM_PPHQ installer.xml || _die "Failed to set the Build Number in the installer project file (pphq/installer.xml)"
   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_pphq_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_pphq_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_pphq_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_pphq_windows || exit 1
    fi
}
