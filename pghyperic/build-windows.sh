#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_pghyperic_windows() {

    # Enter the source directory and cleanup if required
    cd $WD/pghyperic/source

    if [ -e pghyperic.windows ];
    then
      echo "Removing existing pghyperic.windows source directory"
      rm -rf pghyperic.windows  || _die "Couldn't remove the existing pghyperic.windows source directory (source/pghyperic.windows)"
    fi
   
    echo "Creating staging directory ($WD/pghyperic/source/pghyperic.windows)"
    mkdir -p $WD/pghyperic/source/pghyperic.windows || _die "Couldn't create the pghyperic.windows directory"

    # Grab a copy of the source tree
    cp -R pghyperic-$PG_VERSION_PGHYPERIC-windows/* pghyperic.windows || _die "Failed to copy the source code (source/pghyperic-$PG_VERSION_PGHYPERIC-windows)"
    chmod -R ugo+w pghyperic.windows || _die "Couldn't set the permissions on the source directory"

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/pghyperic/staging/windows ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/pghyperic/staging/windows || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/pghyperic/staging/windows)"
    mkdir -p $WD/pghyperic/staging/windows || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/pghyperic/staging/windows || _die "Couldn't set the permissions on the staging directory"
    cp -R $WD/pghyperic/source/pghyperic.windows/* $WD/pghyperic/staging/windows || _die "Failed to copy the pghyperic Source into the staging directory"
    

}

################################################################################
# PG Build
################################################################################

_build_pghyperic_windows() {

    cd $WD
    # Copy the various support files into place
    mkdir -p pghyperic/staging/windows/instscripts || _die "Failed to create the instscripts directory"
    cp -R server/staging/windows/lib/libpq* pghyperic/staging/windows/instscripts/ || _die "Failed to copy libpq in instscripts"
    cp -R server/staging/windows/bin/psql.exe pghyperic/staging/windows/instscripts/ || _die "Failed to copy psql in instscripts"
    cp -R server/staging/windows/bin/gssapi32.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/ssleay32.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libeay32.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/iconv.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libintl-8.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libiconv-2.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/comerr32.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/krb5_32.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/k5sprt32.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxml2.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/libxslt.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/zlib1.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    cp -R server/staging/windows/bin/msvcr71.dll pghyperic/staging/windows/instscripts/ || _die "Failed to copy dependent libs"
    # Setup the installer scripts. 
    scp $PG_SSH_WINDOWS:C:\\\\pgBuild\\\\vcredist\\\\vcredist_x86.exe pghyperic/staging/windows/instscripts/vcredist_x86.exe || _die "Failed to copy the VC++ runtimes on the windows build host"
    cp pghyperic/scripts/windows/installruntimes.vbs pghyperic/staging/windows/instscripts/installruntimes.vbs || _die "Failed to copy the installruntimes script ($WD/scripts/windows/instscripts/installruntimes.vbs)"

}


################################################################################
# PG Build
################################################################################

_postprocess_pghyperic_windows() {
 
    cd $WD/pghyperic

    # Setup the installer scripts.
    mkdir -p staging/windows/installer/pghyperic || _die "Failed to create a directory for the install scripts"

    cp scripts/tune-os.sh staging/windows/installer/pghyperic/tune-os.sh || _die "Failed to copy the tuneos.sh script (scripts/tuneos.sh)"
    chmod ugo+x staging/windows/installer/pghyperic/tune-os.sh

    cp scripts/hqdb.sql staging/windows/installer/pghyperic/hqdb.sql || _die "Failed to copy the hqdb.sql script (scripts/hqdb.sql)"

    # Copy in the menu pick images
    mkdir -p staging/windows/scripts/images || _die "Failed to create a directory for the menu pick images"
    cp resources/*.ico staging/windows/scripts/images || _die "Failed to copy the menu pick images (resources/*.png)"

    # Build the installer
    "$PG_INSTALLBUILDER_BIN" build installer.xml windows || _die "Failed to build the installer"

    # Sign the installer
    win32_sign "pghyperic-$PG_VERSION_PGHYPERIC-windows.exe"
	
    cd $WD
}

