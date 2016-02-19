#!/bin/bash

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

_set_permissions() {

    permissionsDirectory="staging/$1/"

    if [ "x$2" != "x" ];
    then
        permissionsDirectory="$2"
    fi

    # Set 644 for all files and folders
    find $permissionsDirectory -type f | xargs -I{} chmod 644 {}

    # Set Permissions for links and folders
    find $permissionsDirectory -xtype l | xargs -I{} chmod 777 {}
    find $permissionsDirectory -type d | xargs -I{} chmod 755 {}

    # " executable" requires a ' ' prefix to ensure it is not a filename
    find $permissionsDirectory -type f | xargs -I{} file {} | grep -i " executable" | cut -f1 -d":" | xargs -I{} chmod +x {}
    find $permissionsDirectory -type f | xargs -I{} file {} | grep "ELF" | cut -f1 -d":" | xargs -I{} chmod +x {}
    find $permissionsDirectory -type f | xargs -I{} file {} | grep "Mach-O" | cut -f1 -d":" | xargs -I{} chmod +x {}
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

            IS_EXECUTABLE=`file $FILE_PATH/$FILE | grep -E "Mach-O executable|Mach-O 64-bit executable" | wc -l`
            IS_SHAREDLIB=`file $FILE_PATH/$FILE | grep -E "(Mach-O\ 64-bit\ dynamically\ linked\ shared\ library|Mach-O\ dynamically\ linked\ shared\ library|Mach-O\ bundle|Mach-O 64-bit bundle)" | wc -l`

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
                                            NEW_DLL=`echo $DLL | sed -e "s^/opt/local/20.*lib/^^g"`
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

                                    NEW_DLL=`echo $DLL | sed -e "s^/opt/local/20.*lib/^lib/^g"`
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
       _die "tarball doesn't exist for the this Package ($FILENAME)"
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
        rsync -av $FILEPATH/$FILENAME $PG_SSH_SIGN_WINDOWS:$PG_CYGWIN_PATH_WINDOWS || _die "Failed to copy the executable to the windows host for signing ($FILEPATH/$FILENAME)"

        while [ $NOT_SIGNED == 1 ]; do
            # We will stop trying, if the count is more than 3
            if [ $COUNT -gt 2 ];
            then
               _warn "Failed to sign the installer ($FILENAME)"
               return
            fi
            NOT_SIGNED=0
            ssh $PG_SSH_SIGN_WINDOWS "cmd /c \"$PG_SIGNTOOL_WINDOWS\" sign /a /t http://timestamp.comodoca.com/authenticode $PG_PATH_WINDOWS/$FILENAME" || NOT_SIGNED=1
            COUNT=`expr $COUNT + 1`
        done
        rsync -av $PG_SSH_SIGN_WINDOWS:$PG_CYGWIN_PATH_WINDOWS/$FILENAME $FILEPATH/$FILENAME || _die "Failed to copy the executable from the windows host after signing ($FILENAME)"
        echo "Removing the signed executable ($FILENAME) from the windows VM..."
        ssh $PG_SSH_SIGN_WINDOWS "cd $PG_PATH_WINDOWS; rm -f $FILENAME" || _die "Failed to remove the signed executable ($FILENAME) on the windows host"
    fi
}

# $1 - Component Name
generate_3rd_party_license()
{
    export ComponentName="$1"
    export ListGeneratorScriptFile="$WD/list-libs-linux.sh"
    export ListGeneratorScriptFileOSX="$WD/list-libs-osx.sh"
    export ListGeneratorScriptFileWin="$WD/list-libs-windows.sh"
    export ListGeneratorScriptFileJar="$WD/list-jars.sh"
    export ListPipModules="$WD/list_pip_libs.sh"
    export ListJSScripts="$WD/list_js_libs.sh"
    export ListpgAdminFiles="$WD/list_pgadmin_files.sh"
    export blnIsWindows=false
    export LibListDir="3rd_party_libraries_list"
    export CurrentPlatform="${PWD##*/}" # Current directory name actually
    export Lib_List_File="$WD/output/$LibListDir/${ComponentName}_${CurrentPlatform}_libs.txt"
    export ComponentFile="$PWD/${ComponentName}_3rd_party_licenses.txt"
    export LicenseTypePath="$WD/resources/3rd_party_license_types"
    export LIBPQPattern="libpq"

    echo "[$FUNCNAME] Component Name: $ComponentName"
    echo "[$FUNCNAME] Library List File: $Lib_List_File"
    echo "[$FUNCNAME] Component File: $ComponentFile"


    mkdir -p "$WD/output/$LibListDir"

    if [[ $(echo $CurrentPlatform | grep -ci "win") -gt 0 ]];
    then
        blnIsWindows=true
        ListGeneratorScriptFile="$ListGeneratorScriptFileWin"
    elif [[ $(echo $CurrentPlatform | grep -ci "osx") -gt 0 ]];
    then
        ListGeneratorScriptFile="$ListGeneratorScriptFileOSX"
    fi

    if [[ $ComponentName != "server" ]];
    then
        LIBPQPattern=xyz${LIBPQPattern}abc
    fi

    TempFile=$(mktemp)
    $ListGeneratorScriptFile    >> $TempFile
    $ListGeneratorScriptFileJar >> $TempFile
    $ListJSScripts >> $TempFile

    if [[ $ComponentName = "languagepack" ]];
    then
	$ListPipModules $PWD >> $TempFile
    fi

    if [[ $ComponentName = "pem_client" ]];
    then
        $ListpgAdminFiles >> $TempFile
    fi

    cat $TempFile | xargs -I{} grep -w {} $WD/resources/files_to_project_map.txt | sort -u | cut -f1 | grep -v $LIBPQPattern | xargs -I{} echo "awk '/\<{}\>/ {print \$1\" {}\"}' $WD/resources/license_to_project_map.txt" | sh | sort -u  > $Lib_List_File

    awk '\
    BEGIN                                                                                                                           \
    {                                                                                                                               \
        prevLicenseName="";                                                                                                         \
        listProject="";                                                                                                             \
        system("rm -f "ENVIRON["ComponentFile"]);                                                                                   \
    }                                                                                                                               \
    {                                                                                                                               \
        gsub(/^project_/, "", $2);                                                                                                  \
                                                                                                                                    \
        if ( $1 == prevLicenseName )                                                                                                \
        {                                                                                                                           \
            listProject=listProject", "$2;                                                                                          \
        }                                                                                                                           \
        else                                                                                                                        \
        {                                                                                                                           \
            if ( listProject != "" )                                                                                                \
            {                                                                                                                       \
                system("echo -e \"==================\n"listProject" license\n==================\" >> "ENVIRON["ComponentFile"]);    \
                system("cat "ENVIRON["LicenseTypePath"]"/"prevLicenseName" >> "ENVIRON["ComponentFile"]);                           \
                system("echo >> "ENVIRON["ComponentFile"]);                                                                         \
            }                                                                                                                       \
            listProject=$2;                                                                                                         \
            prevLicenseName=$1;                                                                                                     \
        }                                                                                                                           \
    }                                                                                                                               \
    END                                                                                                                             \
    {                                                                                                                               \
        if ( listProject != "" )                                                                                                    \
        {                                                                                                                           \
            system("echo -e \"==================\n"listProject" license\n==================\" >> "ENVIRON["ComponentFile"]);        \
            system("cat "ENVIRON["LicenseTypePath"]"/"prevLicenseName" >> "ENVIRON["ComponentFile"]);                               \
            system("echo >> "ENVIRON["ComponentFile"]);                                                                             \
        }                                                                                                                           \
    }' $Lib_List_File


    if [[ ! -s $ComponentFile ]];
    then
        rm -f $ComponentFile
    fi

    if [[ -f $ComponentFile ]];
    then
        if [[ $blnIsWindows == true ]];
        then
                unix2dos $ComponentFile || _die "Unable to convert 3rd party license file [$ComponentFile] to dos format."
        else
                dos2unix $ComponentFile || _die "Unable to convert 3rd party license file [$ComponentFile] to unix format."
        fi

        chmod 444 $ComponentFile
    fi
}

