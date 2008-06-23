#!/bin/sh

# PostgreSQL server shared library path rewrite script for OSX
# Dave Page, EnterpriseDB

#Check the command line
if [ $# -ne 2 ];
then
    echo "Usage: $0 <Staging dir> <Install dir>"
    exit 127
fi

echo "Called as: $0 $1 $2"

STAGINGDIR=$1
INSTALLDIR=$2

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
    sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
	mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
}

# Find all the files that mention the staging directory
FLIST=`grep -Ril "$STAGINGDIR" "$INSTALLDIR/"*`

for FILE in $FLIST; do

    # We need to ignore symlinks
    IS_SYMLINK=`file $FILE | grep "symbolic link" | wc -l`

    if [ $IS_SYMLINK -eq 0 ]; then

        # Use install_name_tool for binaries
        IS_BINARY=`file $FILE | grep Mach-O | wc -l`

        if [ $IS_BINARY -eq 0 ]; then
            echo "Post-processing text file: $FILE"
            _replace "$STAGINGDIR" "$INSTALLDIR" "$FILE"
        else
            echo "Post-processing binary file: $FILE"
			
            # Change the library ID
            ID=`otool -D $FILE | grep "$STAGINGDIR"`

            for DLL in $ID; do
                echo "    - rewriting ID: $DLL"

                NEW_DLL=`echo $DLL | sed -e "s^$STAGINGDIR^$INSTALLDIR^g"`
                echo "                to: $NEW_DLL"
					
                install_name_tool -id "$NEW_DLL" "$FILE" 
            done
				
            # Now change the referenced libraries
            DLIST=`otool -L $FILE | grep "$STAGING" | awk '{ print $1 }'`

            for DLL in $DLIST; do
                echo "    - rewriting ref: $DLL"

                NEW_DLL=`echo $DLL | sed -e "s^$STAGINGDIR^$INSTALLDIR^g"`
                echo "                 to: $NEW_DLL"
					
                install_name_tool -change "$DLL" "$NEW_DLL" "$FILE" 
           done
        fi
    fi
done

echo "$0 ran to completion"
exit 0
