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

    # Get a fresh tree
    if [ -d PPHQ ];
    then
        echo "Cleaning and updating existing tree..."
        cd PPHQ
        git reset --hard || _die "Unable to clean the tree!"
        git pull || _die "Unable to update the tree!"
        cd ..
    else
        echo "Checking out a fresh source tree"
        git clone ssh://pginstaller@cvs.enterprisedb.com/git/PPHQ || _die "Failed to checkout a copy of the PPHQ source tree"
    fi
  
    # pphq
#    if [ -d hq ];
#    then
#        echo "Removing existing hyperic directory..."
#        rm -rf hq || _die "Couldn't remove the existing hyperic source directory (source/hq)"
#    fi

#    echo "Creating a working copy of the source..."
#    cp -R PPHQ hq || _die "Unable to create a working copy of the source tree!"

#    if [ ! -d jboss-${PPHQ_JBOSS_VERSION} ];
#    then
#      echo "Extracting jboss binaries..."
#      extract_file ${WD}/tarballs/jboss-${PPHQ_JBOSS_VERSION} || _die "Error extracting jboss binaries for pphq..."
#    fi
#
#    echo "Fixing up the PPHQ source tree..."
#    mv $WD/pphq/source/hq/hq_bin/launcher_bin/hq-server.exe $WD/pphq/source/hq/hq_bin/launcher_bin/pphq-server.exe || _die "Couldn't rename hq-server.exe"
#    mv $WD/pphq/source/hq/hq_bin/launcher_bin/hq-agent.exe $WD/pphq/source/hq/hq_bin/launcher_bin/pphq-agent.exe || _die "Couldn't rename hq-agent.exe"
#    if [ ! -d $WD/pphq/source/hq/unittest/emptydir ];
#    then
#      mkdir $WD/pphq/source/hq/unittest/emptydir || _die "Failed to create $WD/pphq/source/hq/unittest/emptydir"
#    fi
#    if [ ! -d $WD/pphq/source/hq/etc/gconsoleTemplates ]; 
#    then
#      mkdir $WD/pphq/source/hq/etc/gconsoleTemplates || _die "Failed to create $WD/pphq/source/hq/etc/gconsoleTemplates"
#    fi
#
#    cd $WD/pphq/source
#    if [ -f build_pphq.sh ];
#    then
#      rm -f build_pphq.sh
#    fi
#
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
#    echo "Building PPHQ..."
#    /bin/bash build_pphq.sh || _die "Error building PPHQ from source..."

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
