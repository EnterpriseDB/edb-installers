#!/bin/bash
# Copyright (c) 2012-2017, EnterpriseDB Corporation.  All rights reserved

# RM 32745
LC_CTYPE_ORG=$LC_CYTPE
LC_CTYPE="C"

# Fatal error handler
_die() {
        echo ""
        echo "FATAL ERROR: $1"
        echo ""
        exit 1
}

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
        sed -e "s^$1^$2^g" "$3" > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
        mv /tmp/$$.tmp "$3" || _die "Failed to move /tmp/$$.tmp to $3"
}

cd "$1"

filelist=`grep -rl @@INSTALL_DIR@@ *`


for file in $filelist
do
_replace @@INSTALL_DIR@@ "$1" "$file"
 chmod +x "$file"
done

LC_CTYPE=$LC_CYTPE_ORG
