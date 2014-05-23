#!/bin/bash

if [ -e $WD/pvt_settings.sh ]
then

    # Source the private settings.    
    source $WD/pvt_settings.sh

    # Create the pvt_packages directory. If not exist.
    if [ ! -e $WD/pvt_packages ];
    then
	mkdir $WD/pvt_packages
    fi

    for PKG in $PVT_PACKAGES;
    do
	C_PKG=PVT_PACKAGE_$PKG
	if [ ${!C_PKG} = 1 ];
	then
	    C_PKG_NAME=PVT_$PKG"_PACKAGE_NAME"
	    C_PKG_INSTALLER_REPO_BRANCH=PVT_$PKG"_INSTALLER_REPO_BRANCH"
	    if [ ! -e $WD/pvt_packages/${!C_PKG_NAME} ];
	    then
		cd $WD/pvt_packages
		# Get the installer source
		C_PKG_INSTALLER_REPO=PVT_$PKG"_INSTALLER_REPO"
		git clone -b ${!C_PKG_INSTALLER_REPO_BRANCH} ${!C_PKG_INSTALLER_REPO}
	    else
		# Update the installer repo
		cd $WD/pvt_packages/${!C_PKG_NAME}
		git checkout ${!C_PKG_INSTALLER_REPO_BRANCH}
		git pull
	    fi
	    # Copy the installer source to proper location.
	    C_PKG_INSTALLER_NAME=PVT_$PKG"_INSTALLER_NAME"
	    C_PKG_INSTALLER_DIR=PVT_$PKG"_INSTALLER_DIR"
	    if [ ! -e $WD/${!C_PKG_INSTALLER_NAME} ];
	    then
		mkdir $WD/${!C_PKG_INSTALLER_NAME}
	    fi		
	    echo "Copying $WD/pvt_packages/${!C_PKG_NAME}/${!C_PKG_INSTALLER_DIR} to $WD/${!C_PKG_INSTALLER_NAME} "	
	    cp -R $WD/pvt_packages/${!C_PKG_NAME}/${!C_PKG_INSTALLER_DIR}/* $WD/${!C_PKG_INSTALLER_NAME}/ || _die "Failed to copy the installer source"
	    #Start the build
	    source $WD/${!C_PKG_INSTALLER_NAME}/build.sh
	    if [ $SKIPBUILD = 0 ];
	    then
		_prep_${!C_PKG_INSTALLER_NAME} || exit 1
	        _build_${!C_PKG_INSTALLER_NAME} || exit 1
	    fi

	    _postprocess_${!C_PKG_INSTALLER_NAME} || exit 1
	fi
    done
fi
