#!/bin/bash
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL stackbuilderplus launch script for Solaris

XTERM=`which xterm`

if [ -e "$XTERM" ];
then
    $XTERM -e "INSTALL_DIR/scripts/runStackBuilderPlus.sh" $*
else
    # xterm not available, so we run the runStackBuilderPlus.sh directly.
    # As in solaris, we are not concerned about menu picks and thus this script can only be launched via terminal.
    # Also in case of root/super user launching this script, this will correctly open the StackbuilderPlus.
    # Note: In Solaris, xterm is in path of a normal user, but when he does a 'su', The PATH env changes and thus, xterm wont be in PATH
    "INSTALL_DIR/scripts/runStackBuilderPlus.sh" $*
fi
