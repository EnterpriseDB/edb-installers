#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

export LD_LIBRARY_PATH=INSTALL_DIR/lib:STACKBUILDER_DIR/lib:$LD_LIBRARY_PATH
nohup INSTALL_DIR/bin/UpdateManager --execute "STACKBUILDER_DIR/scripts/launchStackBuilder.sh" > /tmp/um_update_manager.log 2>&1 &
rm -f /tmp/um_update_manager.log

