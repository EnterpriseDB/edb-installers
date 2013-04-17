#!/bin/sh
# Copyright (c) 2012-2013, EnterpriseDB Corporation.  All rights reserved

# Postgres Plus Advanced Server Stackbuilder Plus runner script for HP-UX

LOADINGUSER=`whoami`
echo "No graphical su/sudo program could be found on your system!"
echo "This window must be kept open while StackBuilder Plus is running."
echo ""

# You're not running this script as root user
if [ x"$LOADINGUSER" != x"root" ];
then
    tmpUserDisplayFile=`mktemp -p .echoUser1DISPLAY`
    tmpUserXauthFile=`mktemp -p .parseUser1Xauth`
    echo $DISPLAY > $tmpUserDisplayFile
    chmod a+r $tmpUserDisplayFile
    xauth list|grep `echo $DISPLAY |cut -c10-12` > $tmpUserXauthFile
    chmod a+r $tmpUserXauthFile

    echo "Please enter the root password when requested."
    su - root -c "sh -c 'xauth add `cat $tmpUserXauthFile`;export DISPLAY=`cat $tmpUserDisplayFile`;LD_LIBRARY_PATH=INSTALL_DIR/lib:$LD_LIBRARY_PATH; export GDK_PIXBUF_MODULE_FILE=../lib/gdk-pixbuf-2.0/2.10.0/loaders.cache;export GDK_PIXBUF_MODULEDIR=../lib/gdk-pixbuf-2.0/2.10.0/loaders/; cd INSTALL_DIR/bin; G_SLICE=always-malloc; INSTALL_DIR/bin/stackbuilderplus $*'"
    rm -f $tmpUserDisplayFile
    rm -f $tmpUserXauthFile
else
   cd INSTALL_DIR/bin
   GDK_PIXBUF_MODULE_FILE=../lib/gdk-pixbuf-2.0/2.10.0/loaders.cache GDK_PIXBUF_MODULEDIR=../lib/gdk-pixbuf-2.0/2.10.0/loaders/ LD_LIBRARY_PATH="INSTALL_DIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALL_DIR/bin/stackbuilderplus" $*
fi

# Wait a while to display su or sudo invalid password error if any
if [ $? -eq 1 ];
then
    sleep 2
fi

