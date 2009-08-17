#!/bin/bash

/usr/bin/osascript << EOF
do shell script "\"INSTALL_DIR/stackbuilderplus.app/Contents/MacOS/stackbuilderplus\" $* &" with administrator privileges
EOF

exit
