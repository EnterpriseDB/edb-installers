#!/bin/sh

export LD_LIBRARY_PATH=INSTALL_DIR/lib:$LD_LIBRARY_PATH
nohup INSTALL_DIR/bin/UpdateManager --execute "INSTALL_DIR/scripts/launchStackBuilderPlus.sh" > /tmp/sbp_update_manager.log 2>&1 &
rm -f /tmp/sbp_update_manager.log

