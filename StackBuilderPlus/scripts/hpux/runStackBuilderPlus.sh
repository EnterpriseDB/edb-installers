#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# Postgres Plus Advanced Server Stackbuilder Plus runner script for HP-UX

# Record the calling shell pid in the pid file.
echo $$ > /tmp/runsbp.pid

LOADINGUSER=`whoami`
echo "No graphical su/sudo program could be found on your system!"
echo "This window must be kept open while StackBuilder Plus is running."
echo ""

# You're not running this script as root user
if [ x"$LOADINGUSER" != x"root" ];
then
    echo $DISPLAY > /tmp/.echoUser1DISPLAY.txt
    chmod a+r /tmp/.echoUser1DISPLAY.txt
    xauth list|grep `echo $DISPLAY |cut -c10-12` > /tmp/.parseUser1Xauth.txt
    chmod a+r /tmp/.parseUser1Xauth.txt

    echo "Please enter the root password when requested."
    su - root -c "sh -c 'xauth add `cat /tmp/.parseUser1Xauth.txt`;export DISPLAY=`cat /tmp/.echoUser1DISPLAY.txt`;LD_LIBRARY_PATH=INSTALL_DIR/lib:$LD_LIBRARY_PATH; export GDK_PIXBUF_MODULE_FILE=../lib/gdk-pixbuf-2.0/2.10.0/loaders.cache;export GDK_PIXBUF_MODULEDIR=../lib/gdk-pixbuf-2.0/2.10.0/loaders/; cd INSTALL_DIR/bin; G_SLICE=always-malloc; INSTALL_DIR/bin/stackbuilderplus $*'"
    rm -f /tmp/.echoUser1DISPLAY.txt
    rm -f /tmp/.parseUser1Xauth.txt
else
   cd INSTALL_DIR/bin
   GDK_PIXBUF_MODULE_FILE=../lib/gdk-pixbuf-2.0/2.10.0/loaders.cache GDK_PIXBUF_MODULEDIR=../lib/gdk-pixbuf-2.0/2.10.0/loaders/ LD_LIBRARY_PATH="INSTALL_DIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALL_DIR/bin/stackbuilderplus" $*
fi

# Wait a while to display su or sudo invalid password error if any
if [ $? -eq 1 ];
then
    sleep 2
fi

# Remove the pid file now.
rm -f /tmp/runsbp.pid

