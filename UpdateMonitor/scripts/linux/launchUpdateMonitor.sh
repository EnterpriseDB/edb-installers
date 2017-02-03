#!/bin/bash
# Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

export LD_LIBRARY_PATH=INSTALL_DIR/lib:STACKBUILDER_DIR/lib:$LD_LIBRARY_PATH
nohup INSTALL_DIR/bin/UpdateManager --execute "STACKBUILDER_DIR/scripts/launchstackbuilder.sh" > /dev/null 2>&1 &

