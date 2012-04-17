#!/bin/bash

_check_copyright_info() {
    BASENAME=`basename $0`
    YEAR=`date | awk '{print $NF}'`

    # Get the file names that contain string "EnterpriseDB Corp" and then grep if it contains the current year. If not then exit
    for file in `find $1 -name "*.sh" -o -name "*.bat" -o -name "*.vbs" | grep -v $BASENAME | grep -v binaries | grep -v staging | grep -v source | xargs grep "EnterpriseDB Corp"| awk '{print $1}' | cut -d":" -f1`
    do
        if ! grep $YEAR $file > /dev/null
        then
            echo "Error: $file does not contain copyright $YEAR. Please change the copyright information in all the required scripts in \"$1\" directory and rerun $BASENAME"
            exit 1
        fi
    done
}

# Fatal error handler
_die() {
    echo ""
    echo "FATAL ERROR: $1"
    echo ""
    cd $WD
    exit 1
}

_warn() {
    echo ""
    echo "WARNING: $*"
    echo ""
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
                                    ID1=`otool -D $FILE_PATH/$FILE | grep "/opt/local" | grep -v ":"`
                                    ID2=`otool -D $FILE_PATH/$FILE | grep "/usr/local" | grep -v ":"`
                                   
                                    for DLL in $ID; do
                                            echo "    - rewriting ID: $DLL"

                                            NEW_DLL=`echo $DLL | sed -e "s^$FILE_PATH/^^g"`
                                            echo "                to: $NEW_DLL"

                                            install_name_tool -id "$NEW_DLL" "$FILE_PATH/$FILE" 
                                    done

                                    for DLL in $ID1; do
                                            echo "    - rewriting ID: $DLL"
                                            NEW_DLL=`echo $DLL | sed -e "s^/opt/local/lib/^^g"`
                                            echo "                to: $NEW_DLL"

                                            install_name_tool -id "$NEW_DLL" "$FILE_PATH/$FILE"
                                    done
                                    
                                    for DLL in $ID2; do
                                            echo "    - rewriting ID: $DLL"
                                            NEW_DLL=`echo $DLL | sed -e "s^/usr/local/lib/^^g"`
                                            echo "                to: $NEW_DLL"

                                            install_name_tool -id "$NEW_DLL" "$FILE_PATH/$FILE"
                                    done
                                    
                            fi

                            # Now change the referenced libraries
                            DLIST=`otool -L $FILE_PATH/$FILE | grep $BASE_PATH | grep -v ":" | awk '{ print $1 }'`
                            DLIST1=`otool -L $FILE_PATH/$FILE | grep "/opt/local" | grep -v ":" | awk '{ print $1 }'`
                            DLIST2=`otool -L $FILE_PATH/$FILE | grep "/usr/local" | grep -v ":" | awk '{ print $1 }'`

                            for DLL in $DLIST; do
                                    echo "    - rewriting ref: $DLL"

                                    NEW_DLL=`echo $DLL | sed -e "s^$BASE_PATH/^^g"`
                                    echo "                 to: $LOADER_PATH/$NEW_DLL"

                                    install_name_tool -change "$DLL" "$LOADER_PATH/$NEW_DLL" "$FILE_PATH/$FILE" 
                            done

                            for DLL in $DLIST1; do
                                    echo "    - rewriting ref: $DLL"

                                    NEW_DLL=`echo $DLL | sed -e "s^/opt/local/^^g"`
                                    echo "                 to: $LOADER_PATH/$NEW_DLL"

                                    install_name_tool -change "$DLL" "$LOADER_PATH/$NEW_DLL" "$FILE_PATH/$FILE" 
                            done

                            for DLL in $DLIST2; do
                                    echo "    - rewriting ref: $DLL"

                                    NEW_DLL=`echo $DLL | sed -e "s^/usr/local/^^g"`
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

    if [ -e $FILENAME.zip ]; then
       # This is a zip file
       unzip -o $FILENAME.zip
    elif [ -e $FILENAME.tar.gz ]; then
       # This is a tar.gz tarball
       tar -zxvf $FILENAME.tar.gz
    elif [ -e $FILENAME.tar.bz2 ]; then
       # This is a tar.bz2 tarball
       tar -jxvf $FILENAME.tar.bz2
    elif [ -e $FILENAME.bz2 ]; then
       # This is a bz2 tarball
       tar -jxvf $FILENAME.bz2
    elif [ -e $FILENAME.tgz ]; then
       # This is a tgz tarball
       tar -zxvf $FILENAME.tgz
    else
       echo "tarball doesn't exist for the this Package ($FILENAME)"
       exit 1
    fi
}

# Sign a Win32 package/binaries
win32_sign()
{
    FILENAME=$1
    FILEPATH=$2
	if [ x"$FILEPATH" == x"" ]; then
        FILEPATH=$WD/output/
	fi
    NOT_SIGNED=1
    COUNT=0

    if [ "$PG_SIGNTOOL_WINDOWS" != "" ];
    then
        echo "Signing $FILEPATH/$FILENAME..."
        scp $FILEPATH/$FILENAME $PG_SSH_WINDOWS:$PG_PATH_WINDOWS || _die "Failed to copy the executable to the windows host for signing ($FILEPATH/$FILENAME)"

        while [ $NOT_SIGNED == 1 ]; do
            # We will stop trying, if the count is more than 3
            if [ $COUNT -gt 2 ];
            then
               _warn "Failed to sign the installer ($FILENAME)"
               return
            fi
            NOT_SIGNED=0
            ssh $PG_SSH_WINDOWS "cmd /c \"$PG_SIGNTOOL_WINDOWS\" sign /a /t http://tsa.starfieldtech.com $PG_PATH_WINDOWS/$FILENAME" || NOT_SIGNED=1
            COUNT=`expr $COUNT + 1`
        done
        scp $PG_SSH_WINDOWS:$PG_PATH_WINDOWS/$FILENAME $FILEPATH/$FILENAME || _die "Failed to copy the executable from the windows host after signing ($FILENAME)"
        echo "Removing the signed executable ($FILENAME) from the windows VM..."
        ssh $PG_SSH_WINDOWS "cd $PG_PATH_WINDOWS; rm -f $FILENAME" || _die "Failed to remove the signed executable ($FILENAME) on the windows host"
    fi
}

