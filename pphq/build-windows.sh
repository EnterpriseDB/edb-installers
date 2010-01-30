#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pphq_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/pphq/source

    if [ -e pphq.windows ];
    then
      echo "Removing existing pphq.windows source directory"
      rm -rf pphq.windows  || _die "Couldn't remove the existing pphq.windows source directory (source/pphq.windows)"
    fi
   
    echo "Creating staging directory ($WD/pphq/source/pphq.windows)"
    mkdir -p $WD/pphq/source/pphq.windows || _die "Couldn't create the pphq.windows directory"

    # Grab a copy of the source tree
    cp -R pphq-$PG_VERSION_PPHQ-windows/* pphq.windows || _die "Failed to copy the source code (source/pphq-$PG_VERSION_PPHQ-windows)"
    chmod -R ugo+w pphq.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pphq/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pphq/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pphq/staging/windows)"
    mkdir -p $WD/pphq/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pphq/staging/windows || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/pphq/source/pphq.windows/* $WD/pphq/staging/windows || _die "Failed to copy the pphq Source into the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pphq_windows() {

    cd $WD
    # Copy the various support files into place
    mkdir -p pphq/staging/windows/instscripts || _die "Failed to create the instscripts directory"
    cp -R server/staging/windows/lib/libpq* pphq/staging/windows/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe pphq/staging/windows/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/gssapi32.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/ssleay32.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/comerr32.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/krb5_32.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/k5sprt32.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/msvcr71.dll pphq/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    # Setup the installer scripts. 
    scp $PG_SSH_WINDOWS:C:\\\\pgBuild\\\\vcredist\\\\vcredist_x86.exe pphq/staging/windows/instscripts/vcredist_x86.exe || _die "Failed to copy the VC++ runtimes on the windows build host"
    cp pphq/scripts/windows/installruntimes.vbs pphq/staging/windows/instscripts/installruntimes.vbs || _die "Failed to copy the installruntimes script ($WD/scripts/windows/instscripts/installruntimes.vbs)"

}


################################################################################
# PG Build
################################################################################

_postprocess_pphq_windows() {
 
    cd $WD/pphq

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/pphq || _die "Failed to create a directory for the install scripts"

    cp scripts/tune-os.sh staging/windows/installer/pphq/tune-os.sh || _die "Failed to copy the tuneos.sh script (scripts/tuneos.sh)"
    chmod ugo+x staging/windows/installer/pphq/tune-os.sh
    
	cp scripts/change_version_str.sh staging/windows/installer/pphq/change_version_str.sh || _die "Failed to copy the change_version_str.sh script (scripts/change_version_str.sh)"
    chmod ugo+x staging/windows/installer/pphq/change_version_str.sh

    cp scripts/hqdb.sql staging/windows/installer/pphq/hqdb.sql || _die "Failed to copy the hqdb.sql script (scripts/hqdb.sql)"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "pphq-$PG_VERSION_PPHQ-$PG_BUILDNUM_PPHQ-windows.exe"
	
    cd $WD
}

