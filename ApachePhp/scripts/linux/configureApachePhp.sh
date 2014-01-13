#!/bin/bash
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

# Check the command line
if [ $# -ne 2 ];
then
    echo "Usage: $0 <Install dir> <Temp dir>"
    exit 127
fi

TEMPDIR=$2

# Fatal error handler
_die() {
        echo ""
        echo "FATAL ERROR: $1"
        echo ""
        exit 1
}

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
        sed -e "s^$1^$2^g" "$3" > "$TEMPDIR/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
        mv $TEMPDIR/$$.tmp "$3" || _die "Failed to move $TEMPDIR/$$.tmp to $3"
}

cd "$1"

filelist=`grep -rl @@INSTALL_DIR@@ *`


for file in $filelist
do
_replace @@INSTALL_DIR@@ "$1" "$file"
 chmod +x "$file"
done


