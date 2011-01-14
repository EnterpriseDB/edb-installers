#!/bin/bash

# Read the various build scripts

# Mac OS X
if [ $PG_ARCH_OSX = 1 ]; 
then
    source $WD/ReplicationServer/build-osx.sh
fi

# Linux
if [ $PG_ARCH_LINUX = 1 ];
then
    source $WD/ReplicationServer/build-linux.sh
fi

# Linux x64
if [ $PG_ARCH_LINUX_X64 = 1 ];
then
    source $WD/ReplicationServer/build-linux-x64.sh
fi

# Windows
if [ $PG_ARCH_WINDOWS = 1 ];
then
    source $WD/ReplicationServer/build-windows.sh
fi
    
# Solaris x64
if [ $PG_ARCH_SOLARIS_X64 = 1 ];
then
    source $WD/ReplicationServer/build-solaris-x64.sh
fi
    
# Solaris sparc
if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
then
    source $WD/ReplicationServer/build-solaris-sparc.sh
fi

################################################################################
# Build preparation
################################################################################

_prep_ReplicationServer() {

    # Create the source directory if required
    if [ ! -e $WD/ReplicationServer/source ];
    then
        mkdir $WD/ReplicationServer/source
    fi

    # Enter the source directory and cleanup if required
    cd $WD/ReplicationServer/source

    # pgJDBC
    if [ -e pgJDBC-$PG_VERSION_PGJDBC ];
    then
      echo "Removing existing pgJDBC-$PG_VERSION_PGJDBC source directory"
      rm -rf pgJDBC-$PG_VERSION_PGJDBC  || _die "Couldn't remove the existing pgJDBC-$PG_VERSION_PGJDBC source directory (source/pgJDBC-$PG_VERSION_PGJDBC)"
    fi

    echo "Unpacking pgJDBC source..."
    extract_file ../../tarballs/pgJDBC-$PG_VERSION_PGJDBC || exit 1

    # ReplicationServer
    if [ -e replicator ];
    then
      cd replicator 
      echo "Updating xDB Replication Server source directory"
      if  [ x$PG_TAG_REPLICATIONSERVER = x ];
      then
      	  CVSROOT=:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-RREP cvs update -PdC
      else
      	  CVSROOT=:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-RREP cvs update -r $PG_TAG_REPLICATIONSERVER -PdC
      fi
    else
      echo "Fetching xDB Replication Server source directory"
      if  [ x$PG_TAG_REPLICATIONSERVER = x ];
      then
          cvs -d:ext:pginstaller@cvs.enterprisedb.com/cvs/EDB-RREP co replicator
      else
          cvs -d:ext:pginstaller@cvs.enterprisedb.com/cvs/EDB-RREP co -r $PG_TAG_REPLICATIONSERVER replicator
      fi
    fi
    cd $WD/ReplicationServer/source
    # DataValidator
    if [ -e DataValidator ]; 
    then
      cd DataValidator
      echo "Updating DataValidator source directory"
      if  [ x$PG_TAG_REPLICATIONSERVER = x ];
      then
          CVSROOT=:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-RREP cvs update -PdC
      else
          CVSROOT=:ext:pginstaller@cvs.enterprisedb.com:/cvs/EDB-RREP cvs update -r $PG_TAG_REPLICATIONSERVER -PdC
      fi
    else
      echo "Fetching xDB DataValidator source directory"
      if  [ x$PG_TAG_REPLICATIONSERVER = x ];
      then
          cvs -d:ext:pginstaller@cvs.enterprisedb.com/cvs/EDB-RREP co DataValidator
      else
          cvs -d:ext:pginstaller@cvs.enterprisedb.com/cvs/EDB-RREP co -r $PG_TAG_REPLICATIONSERVER DataValidator
      fi
    fi

    # Per-platform prep
    cd $WD
    
    # Mac OS X
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _prep_ReplicationServer_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _prep_ReplicationServer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _prep_ReplicationServer_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _prep_ReplicationServer_windows || exit 1
    fi
    
    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _prep_ReplicationServer_solaris_x64 || exit 1
    fi
    
    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _prep_ReplicationServer_solaris_sparc || exit 1
    fi

}

################################################################################
# Build ReplicationServer
################################################################################

_build_ReplicationServer() {

    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _build_ReplicationServer_osx || exit 1
    fi

    # Linux 
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _build_ReplicationServer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
       _build_ReplicationServer_linux_x64 || exit 1
    fi

    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
        _build_ReplicationServer_windows || exit 1
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
       _build_ReplicationServer_solaris_x64 || exit 1
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
       _build_ReplicationServer_solaris_sparc || exit 1
    fi

}

################################################################################
# Postprocess ReplicationServer
################################################################################
#
# Note that this is the only step run if we're executed with -skipbuild so it must
# be possible to run this against a pre-built tree.
_postprocess_ReplicationServer() {

    cd $WD/ReplicationServer

    XDB_SERVICE_VER=`echo $PG_MAJOR_VERSION | sed 's/\.//'`
    # Prepare the installer XML file
    if [ -f installer.xml ];
    then
        rm installer.xml
    fi
    cp installer.xml.in installer.xml || _die "Failed to copy the installer project file (ReplicationServer/installer.xml.in)"
    
    _replace PG_VERSION_REPLICATIONSERVER $PG_VERSION_REPLICATIONSERVER installer.xml || _die "Failed to set the version in the installer project file (ReplicationServer/installer.xml)"
    _replace PG_BUILDNUM_REPLICATIONSERVER $PG_BUILDNUM_REPLICATIONSERVER installer.xml || _die "Failed to set the Build Number in the installer project file (ReplicationServer/installer.xml)"
    _replace PG_MAJOR_VERSION $PG_MAJOR_VERSION installer.xml || _die "Failed to set the pg version string in the installer project file ($WD/ReplicationServer/installer.xml)"
    _replace XDB_SERVICE_VER $XDB_SERVICE_VER installer.xml || _die "Failed to set the xdb service version string in the installer project file ($WD/ReplicationServer/installer.xml)"

   
    # Mac OSX
    if [ $PG_ARCH_OSX = 1 ]; 
    then
        _postprocess_ReplicationServer_osx || exit 1
    fi

    # Linux
    if [ $PG_ARCH_LINUX = 1 ];
    then
        _postprocess_ReplicationServer_linux || exit 1
    fi

    # Linux x64
    if [ $PG_ARCH_LINUX_X64 = 1 ];
    then
        _postprocess_ReplicationServer_linux_x64 || exit 1
    fi
    
    # Windows
    if [ $PG_ARCH_WINDOWS = 1 ];
    then
       _postprocess_ReplicationServer_windows || exit 1
    fi

    # Solaris x64
    if [ $PG_ARCH_SOLARIS_X64 = 1 ];
    then
        _postprocess_ReplicationServer_solaris_x64 || exit 1
    fi

    # Solaris sparc
    if [ $PG_ARCH_SOLARIS_SPARC = 1 ];
    then
        _postprocess_ReplicationServer_solaris_sparc || exit 1
    fi
    
}
