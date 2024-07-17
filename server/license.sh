WD="$(dirname "$PWD")"

# $1 - Component Name
generate_3rd_party_license()
{
    export ComponentName="$1"
    export ListGeneratorScriptFileWin="$WD/list-libs-windows.sh"
    export ListGeneratorScriptFileJar="$WD/list-jars.sh"
    export ListPipModules="$WD/list_pip_libs.sh"
    export ListJSScripts="$WD/list_js_libs.sh"
    export ListpgAdminFiles="$WD/list_pgadmin_files.sh"
    export blnIsWindows=false
    export LibListDir="3rd_party_libraries_list"
    export CurrentDir="$PWD"
    export ComponentFile="$PWD/${ComponentName}_3rd_party_licenses.txt"
    export LicenseTypePath="$WD/resources/3rd_party_license_types"
    export LIBPQPattern="libpq"

    echo "[$FUNCNAME] Component Name: $ComponentName"
    echo "[$FUNCNAME] Library List File: $Lib_List_File"

    echo "[$FUNCNAME] Component File: $ComponentFile"


    mkdir -p "$WD/output/$LibListDir"

    blnIsWindows=true
    ListGeneratorScriptFile="$ListGeneratorScriptFileWin"
    CurrentPlatform="windows"

    export Lib_List_File="$WD/output/$LibListDir/${ComponentName}_${CurrentPlatform}_libs.txt"

    if [[ $ComponentName != "server" || $ComponentName != "commandlinetools" ]];
    then
        LIBPQPattern=xyz${LIBPQPattern}abc
    fi

    TempFile=$(mktemp)
    $ListGeneratorScriptFile    >> $TempFile
    $ListGeneratorScriptFileJar >> $TempFile
    $ListJSScripts >> $TempFile

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

    echo "cat componentfile"
    cat $ComponentFile

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

pushd ../installer/server/staging/windows-x64/commandlinetools
generate_3rd_party_license "commandlinetools"
popd

pushd ../installer/server/staging/windows-x64/stackbuilder
generate_3rd_party_license "StackBuilder"
popd

pushd ../installer/server/staging/windows-x64/pgadmin4
generate_3rd_party_license "pgAdmin"
popd