#!/bin/bash

export LD_LIBRARY_PATH=INSTALL_DIR/lib:$LD_LIBRARY_PATH
nohup INSTALL_DIR/bin/UpdateManager --server MONITOR_SERVER --execute "INSTALL_DIR/scripts/launchStackBuilderPlus.sh --server=" > /tmp/sbp_update_manager.log 2>&1 &

