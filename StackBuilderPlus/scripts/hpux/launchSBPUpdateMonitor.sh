#!/bin/sh
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

export LD_LIBRARY_PATH=INSTALL_DIR/lib:$LD_LIBRARY_PATH
nohup INSTALL_DIR/bin/UpdateManager --execute "INSTALL_DIR/scripts/launchStackBuilderPlus.sh" > /dev/null 2>&1 &

