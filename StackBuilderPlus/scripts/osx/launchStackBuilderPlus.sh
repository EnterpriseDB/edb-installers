#!/bin/bash
# Copyright (c) 2012-2013, EnterpriseDB Corporation.  All rights reserved

/usr/bin/osascript << EOF
do shell script "\"INSTALL_DIR/stackbuilderplus.app/Contents/MacOS/stackbuilderplus\" $* &" with administrator privileges
EOF

exit
