#!/bin/sh

# PostgreSQL stackbuilder runner script for Linux
# Dave Page, EnterpriseDB

# Record the calling shell pid in the pid file.
echo $$ > /tmp/runsbp.pid

LOADINGUSER=`whoami`
echo "No graphical su/sudo program could be found on your system!"
echo "This window must be kept open while StackBuilder Plus is running."
echo ""

# You're not running this script as root user
if [ x"$LOADINGUSER" != x"root" ];
then
    echo "Please enter the root password when requested."
    su - root -c "LD_LIBRARY_PATH="INSTALL_DIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALL_DIR/bin/stackbuilderplus" $*"
else
    LD_LIBRARY_PATH="INSTALL_DIR/lib":$LD_LIBRARY_PATH G_SLICE=always-malloc "INSTALL_DIR/bin/stackbuilderplus" $*
fi

# Wait a while to display su or sudo invalid password error if any
if [ $? -eq 1 ];
then
    sleep 2
fi

# Remove the pid file now.
rm -f /tmp/runsbp.pid

