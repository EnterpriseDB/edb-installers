#!/bin/bash

if [ "$1" != "" ]; then
    ARGS=--server $1
fi

/usr/bin/osascript << EOF
do shell script "\"INSTALL_DIR/stackbuilderplus.app/Contents/MacOS/stackbuilderplus\" $ARGS &" with administrator privileges
EOF

exit
