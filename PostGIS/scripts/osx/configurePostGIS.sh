#!/bin/bash
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

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

filelist=`grep -rl @@INSTALL_DIR@@ share`


for file in $filelist
do
_replace @@INSTALL_DIR@@ "$1" "$file"
 chmod +x "$file"
done

############################################################
#Configuring the libraries and share files
############################################################

#Copying the lib files to PG LIB DIR
echo "#!/bin/bash" > $1/PostGIS/installer/PostGIS/removeFiles.sh
echo "#Remove these files installed in the lib directory" >> $1/PostGIS/installer/PostGIS/removeFiles.sh

cd $1/PostGIS
filelist=`ls lib`
for file in $filelist
do 
     if [ ! -e $1/lib ];
     then
            mkdir -p  $1/lib
            chmod  a+w $1/lib
     fi
     cp lib/$file $1/lib/
     echo "rm -f $1/lib/$file" >> $1/PostGIS/installer/PostGIS/removeFiles.sh    
done 
rm -rf lib

chmod ugo+x $1/PostGIS/installer/PostGIS/removeFiles.sh
