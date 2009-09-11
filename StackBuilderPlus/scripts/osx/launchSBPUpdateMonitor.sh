#!/bin/bash

cd INSTALL_DIR/UpdateManager.app/Contents/MacOS
INSTALL_DIR/UpdateManager.app/Contents/MacOS/UpdateManager --server MONITOR_SERVER --execute "INSTALL_DIR/scripts/launchStackBuilderPlus.sh" &

