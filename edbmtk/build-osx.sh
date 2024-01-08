#!/bin/bash

    
################################################################################
# Build preparation
################################################################################

_prep_edbmtk_osx() {

    # Enter the source directory and cleanup if required
    cd $WD/edbmtk/source

    if [ -e edbmtk.osx ];
    then
      echo "Removing existing edbmtk.osx source directory"
      rm -rf edbmtk.osx  || _die "Couldn't remove the existing edbmtk.osx source directory (source/edbmtk.osx)"
    fi
   
    echo "Creating staging directory ($WD/edbmtk/source/edbmtk.osx)"
    mkdir -p edbmtk.osx || _die "Couldn't create the edbmtk.osx directory"
    chmod 755 edbmtk.osx || _die "Couldn't set the permissions on the source directory"
    # Grab a copy of the source tree
    cp -R EDB-MTK/* edbmtk.osx || _die "Failed to copy the source code (source/edbmtk-$EDB_VERSION_EDBMTK)"
    
     # Download edb-jdbc18.jar from redux store
    wget http://redux-store.ox.uk.enterprisedb.com/store/live_jdbc_jars/edb-jdbc18.jar
    mv edb-jdbc18.jar edbmtk.osx/lib  || _die "Failed to copy edb-jdbc18.jar from redux store to source."

    wget http://redux-store.ox.uk.enterprisedb.com/store/mtkjars/drivers/ojdbc8.jar
    mv ojdbc8.jar edbmtk.osx/lib  || _die "Failed to copy ojdbc8.jar from redux store to source."

    chmod -R 755 edbmtk.osx || _die "Couldn't set the permissions on the source directory"

    wget --no-check-certificate https://jdbc.postgresql.org/download/postgresql-42.5.0.jar

    mv postgresql-42.5.0.jar edbmtk.osx/lib/ || _die "Failed to copy the pg-jdbc driver"

    # Creating tar file with mtk sources.
    tar -jcvf edbmtk.tar.bz2 edbmtk.osx

    # Remove any existing staging directory that might exist, and create a clean one
    if [ -e $WD/edbmtk/staging/osx ];
    then
      echo "Removing existing staging directory"
      rm -rf $WD/edbmtk/staging/osx || _die "Couldn't remove the existing staging directory"
    fi

    echo "Creating staging directory ($WD/edbmtk/staging/osx)"
    mkdir -p $WD/edbmtk/staging/osx || _die "Couldn't create the staging directory"
    chmod ugo+w $WD/edbmtk/staging/osx || _die "Couldn't set the permissions on the staging directory"

    mkdir -p $WD/edbmtk/staging/osx/scripts
    #cp $WD/MetaInstaller-AS/scripts/uuid_gen.c $WD/edbmtk/staging/osx/scripts || _die "Failed to copy uuid_gen.c"

    # Remove existing source and staging directories
    ssh $EDB_SSH_OSX "if [ -d $EDB_PATH_OSX/edbmtk ]; then rm -rf $EDB_PATH_OSX/edbmtk/*; fi" || _die "Couldn't remove the existing files on OS X build server"

    echo "Copy the sources to the build VM"
    ssh $EDB_SSH_OSX "mkdir -p $EDB_PATH_OSX/edbmtk/source" || _die "Failed to create the source dircetory on the build VM"
    ssh $EDB_SSH_OSX "mkdir -p $EDB_PATH_OSX/edbmtk/staging/osx" || _die "Failed to create the staging dircetory on the build VM"
    scp $WD/edbmtk/source/edbmtk.tar.bz2 $EDB_SSH_OSX:$EDB_PATH_OSX/edbmtk/source/ || _die "Failed to copy the source archives to build VM"

    echo "Extracting the archives"
    ssh $EDB_SSH_OSX "cd $EDB_PATH_OSX/edbmtk/source; tar -jxvf edbmtk.tar.bz2"
}

################################################################################
# PG Build
################################################################################

_build_edbmtk_osx() {

    # build migrationtoolkit
    EDB_STAGING=$EDB_PATH_OSX/edbmtk/staging/osx

    echo "Building migrationtoolkit"
    ssh $EDB_SSH_OSX "cd $EDB_PATH_OSX/edbmtk/source/edbmtk.osx; JAVA_HOME=$EDB_JAVA_HOME_OSX $EDB_MAVEN_HOME_OSX/bin/mvn initialize " || _die "Couldn't initialize the migrationtoolkit"
ssh $EDB_SSH_OSX "cd $EDB_PATH_OSX/edbmtk/source/edbmtk.osx; export PATH=/Users/buildfarm/gaurav/apache-ant-1.10.13/bin:$PATH; JAVA_HOME=$EDB_JAVA_HOME_OSX $EDB_MAVEN_HOME_OSX/bin/mvn clean " || _die "Couldn't clean the migrationtoolkit"
ssh $EDB_SSH_OSX "cd $EDB_PATH_OSX/edbmtk/source/edbmtk.osx; export PATH=/Users/buildfarm/gaurav/apache-ant-1.10.13/bin:$PATH; JAVA_HOME=$EDB_JAVA_HOME_OSX $EDB_MAVEN_HOME_OSX/bin/mvn package " || _die "Couldn't package the migrationtoolkit"
    #Removing JDBC jar as we dont need to ship it now
    ssh $EDB_SSH_OSX "cd $EDB_PATH_OSX/edbmtk/source/edbmtk.osx; rm -rf install/lib/edb-jdbc18.jar" || _die "Unable to remove edb jdbc jar from distro"

    # Copying the MigrationToolKit binary to staging directory
    ssh $EDB_SSH_OSX "cd $EDB_PATH_OSX/edbmtk/source/edbmtk.osx; cp -R install/* $EDB_STAGING" || _die "Couldn't copy the binaries to the migrationtoolkit staging directory (edbmtk/staging/osx)"

    #ssh $EDB_SSH_OSX "cd $EDB_PATH_OSX/edbmtk/staging/osx/scripts; gcc -I /opt/local/Current/include uuid_gen.c /opt/local/Current/lib/libuuid.a -o uuid_gen" || _die "Failed to build uuid_gen utility"

    # Copy the staging to controller to build the installers
    ssh $EDB_SSH_OSX "cd $EDB_PATH_OSX/edbmtk/staging/osx; tar -jcvf edbmtk-staging.tar.bz2 *" || _die "Failed to create archive of the edbmtk staging"
    scp $EDB_SSH_OSX:$EDB_PATH_OSX/edbmtk/staging/osx/edbmtk-staging.tar.bz2 $WD/edbmtk/staging/osx || _die "Failed to scp edbmtk staging"

    # Extracting the staging archive
#    cd $WD/edbmtk/staging/osx
#    tar -jxvf edbmtk-staging.tar.bz2 || _die "Failed to extract the edbmtk staging archive"
#    rm -f edbmtk-staging.tar.bz2 || _die "Failed to remove the edbmtk staging archive"
#    rm -f $WD/edbmtk/staging/osx/bin/*.bat || _die "Failed to remove .bat files from bin directory"

}


################################################################################
# PG Build
################################################################################

_postprocess_edbmtk_osx() {

    # copy tar here so that we can run skipbuild 
    scp $EDB_SSH_OSX:$EDB_PATH_OSX/edbmtk/staging/osx/edbmtk-staging.tar.bz2 $WD/edbmtk/staging/osx || _die "Failed to scp edbmtk staging"
    ls -l $WD/edbmtk/staging/osx/edbmtk-staging.tar.bz2

    cd $WD/edbmtk

    scp $WD/versions.sh $WD/common.sh $WD/settings.sh ../resources/entitlements.xml $EDB_SSH_OSX_SIGN:$EDB_PATH_OSX_SIGN

    cd $WD/edbmtk/staging/osx
    tar -jxvf edbmtk-staging.tar.bz2 || _die "Failed to extract the edbmtk staging archive"
    rm -f edbmtk-staging.tar.bz2 || _die "Failed to remove the edbmtk staging archive"
    rm -f $WD/edbmtk/staging/osx/bin/*.bat || _die "Failed to remove .bat files from bin directory"

    cd $WD/edbmtk

    pushd staging/osx
    generate_3rd_party_license "${EDBMTK_INSTALLER_NAME_PREFIX}" 
    popd

    CORE_EDBMTK_VERSION=`echo $EDB_VERSION_EDBMTK | cut -f1 -d"."` || _die "Failed to get CORE_EDBMTK_VERSION"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/osx/bin/runMTK.sh || _die "Failed to put $CORE_EDBMTK_VERSION in runMTK.sh"

    mkdir -p staging/osx/etc/sysconfig || _die "Failed to create etc/sysconfig directory"

    cp scripts/common/edbmtk.config staging/osx/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to create file edbmtk-$CORE_EDBMTK_VERSION.config"
    cp $WD/scripts/common_scripts/runJavaApplication.sh staging/osx/etc/sysconfig/ || _die "Failed to copy runJavaApplication.sh"

    cp -R $WD/server/scripts/osx/sysinfo.sh $WD/edbmtk/staging/osx/scripts || _die "Failed to copy the sysinfo.sh (edbmtk/staging/osx/)"

    _replace CORE_EDBMTK_VERSION $CORE_EDBMTK_VERSION staging/osx/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config || _die "Failed to put CORE_EDBMTK_VERSION in edbmtk-$CORE_EDBMTK_VERSION.config"

    chmod ugo+x staging/osx/etc/sysconfig/edbmtk-$CORE_EDBMTK_VERSION.config

    #Mark all files except bin folder as 644 (rw-r--r--)
    find ./staging/osx -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;
    #Mark all files under bin as 755
    find ./staging/osx -type f -regex '.*/bin/*.*' -exec chmod 755 {} \;
    #Mark all directories with 755(rwxr-xr-x)
    find ./staging/osx -type d -exec chmod 755 {} \;
    #Mark all sh with 755 (rwxr-xr-x)
    find ./staging/osx -name \*.sh -exec chmod 755 {} \;

    cd $WD/edbmtk/staging/osx && tar -jcvf edbmtk-staging.tar.bz2 * || _die "Failed to tar the edbmtk staging archive"
    scp $WD/edbmtk/staging/osx/edbmtk-staging.tar.bz2  $EDB_SSH_OSX_SIGN:$EDB_PATH_OSX_SIGN || exit 1
    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN; rm -rf mtk-staging* && mkdir -p mtk-staging; cd mtk-staging; tar -jxvf ../edbmtk-staging.tar.bz2; rm -rf ../edbmtk-staging.tar.bz2;" || _die "Failed to extract mtk staging on sign machine."


    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_libraries mtk-staging" || _die "Failed to do libraries signing"
    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_bundles mtk-staging" || _die "Failed to do bundle signing"
    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN; source settings.sh; source common.sh;sign_binaries mtk-staging" || _die "Failed to do binaries signing"
    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN/mtk-staging;  tar -jcvf ../edbmtk-staging.tar.bz2 *"

    scp $EDB_SSH_OSX_SIGN:$EDB_PATH_OSX_SIGN/edbmtk-staging.tar.bz2 $WD/edbmtk/staging/osx/
    #chmod 755 $WD/edbmtk/staging/osx/scripts/uuid_gen || _die "Failed to set permissions uuid_gen"
    cd $WD/edbmtk
    # Build the installer
    echo "Building the installer with the root privileges not required"
    "$EDB_INSTALLBUILDER_BIN" build installer.xml osx || _die "Failed to build the installer"

    # Zip up the output
    cd $WD/output

    # Copy the versions file to signing server
    scp $WD/versions.sh $WD/common.sh $WD/settings.sh ../resources/entitlements.xml $EDB_SSH_OSX_SIGN:$EDB_PATH_OSX_SIGN
    # Scp the app bundle to the signing machine for signing
    tar -jcvf $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app.tar.bz2 $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app
    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN/output; rm -rf $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK*" || _die "Failed to clean the $EDB_PATH_OSX_SIGN/output directory on sign server."
    scp $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app.tar.bz2 $EDB_SSH_OSX_SIGN:$EDB_PATH_OSX_SIGN/output/
    rm -fr $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app*

    # Sign the app
    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN/output; source $EDB_PATH_OSX_SIGN/versions.sh; tar -jxvf $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app.tar.bz2; security unlock-keychain -p $KEYCHAIN_PASSWD ~/Library/Keychains/login.keychain; codesign --verbose --verify --deep -f -i 'com.edb.postgresql' -s '$DEVELOPER_ID' --options runtime --entitlements $EDB_PATH_OSX_SIGN/entitlements.xml $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app;" || _die "Failed to sign the code"
    #ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN/output; rm -rf $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app; mv $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx-signed.app  $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app;" || _die "could not move the signed app"


    #macOS signing certificate check
    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN/output; codesign --verify -vvvv $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app"
    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN/output; codesign -vvv $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app | grep "CSSMERR_TP_CERT_EXPIRED" > /dev/null" && _die "macOS signing certificate is expired. Please renew the certs and build again"

    ssh $EDB_SSH_OSX_SIGN "cd $EDB_PATH_OSX_SIGN/output; zip -r $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.zip $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.app/" || _die "Failed to zip the installer bundle"
    scp $EDB_SSH_OSX_SIGN:$EDB_PATH_OSX_SIGN/output/$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.zip $WD/output || _die "Failed to copy installers to $WD/output."
   echo "Signing of installer done ***********************"
   # Notarize the OS X installer
 #  ssh $EDB_SSH_OSX_NOTARY "mkdir -p $EDB_PATH_OSX_NOTARY; cp $EDB_PATH_OSX_SIGN/settings.sh $EDB_PATH_OSX_NOTARY; cp $EDB_PATH_OSX_SIGN/common.sh $EDB_PATH_OSX_NOTARY" || _die "Failed to create $EDB_PATH_OSX_NOTARY"
   ssh $EDB_SSH_OSX_NOTARY "cd $EDB_PATH_OSX_NOTARY; rm -rf $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx*" || _die "Failed to remove the installer from notarization installer directory"
   scp $WD/output/$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.zip $EDB_SSH_OSX_NOTARY:$EDB_PATH_OSX_NOTARY || _die "Failed to copy installers to $EDB_PATH_OSX_NOTARYi"
   scp $WD/settings.sh  $WD/common.sh $EDB_SSH_OSX_NOTARY:$EDB_PATH_OSX_NOTARY || _die "Failed to copy setting.sh and common.sh to $EDB_PATH_OSX_NOTARY"
   scp $WD/resources/notarize_apps.sh $EDB_SSH_OSX_NOTARY:$EDB_PATH_OSX_NOTARY || _die "Failed to copy notarize_apps.sh to $EDB_PATH_OSX_NOTARY"

   echo ssh $EDB_SSH_OSX_NOTARY "cd $EDB_PATH_OSX_NOTARY; ./notarize_apps.sh $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.zip edbmtk" || _die "Failed to notarize the app"
   ssh $EDB_SSH_OSX_NOTARY "cd $EDB_PATH_OSX_NOTARY; ./notarize_apps.sh $EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.zip edbmtk" || _die "Failed to notarize the app"
   scp $EDB_SSH_OSX_NOTARY:$EDB_PATH_OSX_NOTARY/$EDBMTK_INSTALLER_NAME_PREFIX-$EDB_VERSION_EDBMTK-$EDB_BUILDNUM_EDBMTK-osx.zip $WD/output || _die "Failed to copy notarized installer to $WD/output."

    cd $WD

    echo "END POST EDBMTK OSX"


    #Copy staging directory
    copy_binaries edbmtk osx

    cd $WD
}

