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
     cp lib/$file $1/lib
     echo "rm -f $1/lib/$file" >> $1/PostGIS/installer/PostGIS/removeFiles.sh
done
rm -rf lib

chmod ugo+x $1/PostGIS/installer/PostGIS/removeFiles.sh
