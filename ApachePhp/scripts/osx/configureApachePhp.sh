#!/bin/bash

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


cd $1/apache/modules/

filelist=`ls libphp*so`
for file in $filelist
do
	sudo install_name_tool -change "libpq.5.dylib" "$1/php/lib/libpq.5.dylib" "$file"
done
