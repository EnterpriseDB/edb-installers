#!/bin/bash

# Fatal error handler
_die() {
    echo ""
    echo "FATAL ERROR: $1"
    echo ""
    cd $WD
    exit 1
}

# Search & replace in a file - _replace($find, $replace, $file) 
_replace() {
        sed -e "s^$1^$2^g" $3 > "/tmp/$$.tmp" || _die "Failed for search and replace '$1' with '$2' in $3"
    mv /tmp/$$.tmp $3 || _die "Failed to move /tmp/$$.tmp to $3"
}

# Rewrite so references on Mac - _rewrite_so_refs($base_path, $file_path, $loader_path)
#
# base_path - The base installation path (normally ($WD/staging/osx)
# file_path - The path to files to rewrite, under $base_path (eg. bin, lib, lib/postgresql)
# loader_path - The prefix to give filename in the rewritten path, to get back to $base_path
_rewrite_so_refs() {

    BASE_PATH=$1
    FILE_PATH=$BASE_PATH/$2
    LOADER_PATH=$3

    FLIST=`ls $FILE_PATH`

    for FILE in $FLIST; do

            IS_EXECUTABLE=`file $FILE_PATH/$FILE | grep "Mach-O executable" | wc -l`
            IS_SHAREDLIB=`file $FILE_PATH/$FILE | grep -E "(Mach-O\ dynamically\ linked\ shared\ library|Mach-O\ bundle)" | wc -l`

               if [ $IS_EXECUTABLE -ne 0 -o $IS_SHAREDLIB -ne 0 ]; then

                    # We need to ignore symlinks
                    IS_SYMLINK=`file $FILE_PATH/$FILE | grep "symbolic link" | wc -l`

                    if [ $IS_SYMLINK -eq 0 ]; then

                            if [ $IS_EXECUTABLE -ne 0 ]; then
                                    echo "Post-processing executable: $FILE_PATH/$FILE"
                            else
                                    echo "Post-processing shared library: $FILE_PATH/$FILE"
                            fi

                            if [ $IS_SHAREDLIB -ne 0 ]; then
                                    # Change the library ID
                                    ID=`otool -D $FILE_PATH/$FILE | grep $BASE_PATH | grep -v ":"`

                                    for DLL in $ID; do
                                            echo "    - rewriting ID: $DLL"

                                            NEW_DLL=`echo $DLL | sed -e "s^$FILE_PATH/^^g"`
                                            echo "                to: $NEW_DLL"

                                            install_name_tool -id "$NEW_DLL" "$FILE_PATH/$FILE" 
                                    done
                            fi

                            # Now change the referenced libraries
                            DLIST=`otool -L $FILE_PATH/$FILE | grep $BASE_PATH | grep -v ":" | awk '{ print $1 }'`

                            for DLL in $DLIST; do
                                    echo "    - rewriting ref: $DLL"

                                    NEW_DLL=`echo $DLL | sed -e "s^$BASE_PATH/^^g"`
                                    echo "                 to: $LOADER_PATH/$NEW_DLL"

                                    install_name_tool -change "$DLL" "$LOADER_PATH/$NEW_DLL" "$FILE_PATH/$FILE" 
                            done
                    fi
            fi
    done
}

#extract_file archived_file
extract_file()
{

    FILENAME=$1

    # Check - if parameter is provided
    if [ "x$FILENAME" == "x" ]; then
        _die "Please provide an archived file as parameter with extract_file function"
    fi

    # Check - if the given file exists
    if [ ! -e $FILENAME ]; then
        _die "The given file does not exist ($FILENAME)"
    fi

    BASENAME=`basename $FILENAME`

    # Convert the given file name to lower case
    LFILENAME=`echo $BASENAME | tr "[:upper:]" "[:lower:]"`
        
    # Check if it is a zip file
    ZIPNAME=`basename $LFILENAME .zip`
    TGZNAME=`basename $LFILENAME .tar.gz`
    if [ "x$TGZNAME" == "x$LFILENAME" ]; then
        TGZNAME=`basename $LFILENAME .tgz`
    fi

    BZ2NAME=`basename $LFILENAME .tar.bz2`

    if [ "x$ZIPNAME" != "x$LFILENAME" ]; then
        # This is a zip file
        unzip -o $FILENAME
    elif [ "x$TGZNAME" != "x$LFILENAME" ]; then
        # This is a tar.gz tarball
        tar -zxvf $FILENAME
    elif [ "x$BZ2NAME" != "x$LFILENAME" ]; then
        # This is a tar.bz2 tarball
        tar -jxvf $FILENAME
    else
        _die "Given file type not supported ($FILENAME)"
    fi
}
