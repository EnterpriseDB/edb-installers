#!/bin/sh

# pgInstaller auto build script
# Dave Page, EnterpriseDB

BASENAME=`basename $0`
DIRNAME=`dirname $0`

declare -a PACKAGES_ARR=(SERVER POSTGIS PGAGENT LANGUAGEPACK)
declare -a ENABLED_PKG_ARR=()
declare -a DECOUPLED_ARR=(LANGUAGEPACK)
# Any changes to this file should be made to all the git branches.

usage()
{
        echo "Usage: $BASENAME [Options]\n"
        echo "    Options:"
        echo "      [-skipbuild boolean]" boolean value may be either "1" or "0"
        echo "      [-packages list]   list of packages. It may include the list of supported platforms separated by comma or all"
        echo "      [-releasebuild boolean] Used to distinguish between daily builds and release builds. A boolean value may be either true or false"
        echo "    Examples:"
        echo "     $BASENAME -skipbuild 0 -packages "server,postgis,pgagent""
        echo "    Note: setting skipbuild to 1 will skip the product build and just create the installer. 'all' option for -packages and -platforms will set all platforms and packages."
        echo ""
        exit 1;
}

# command line arguments
while [ "$#" -gt "0" ]; do
        case "$1" in
                -skipbuild) SKIPBUILD=$2; shift 2;;
                -platforms) PLATFORMS=$2; shift 2;;
                -packages) PACKAGES=$2; shift 2;;
                -releasebuild) RELEASEBUILD=$2; shift 2;;
                -help|-h) usage;;
                *) echo -e "error: no such option $1. -h for help"; exit 1;;
        esac
done

# packages variable value cannot be empty.
if [ "$PACKAGES" = "" ]
then
        echo "Error: Please specify the packages list"
        exit 3
fi

# required by build.sh
if $SKIPBUILD ;
then
	SKIPBUILD="-skipbuild"
else
	SKIPBUILD=""
fi

_set_config_package()
{
	if echo $PACKAGES | grep -w -i $1 > /dev/null
        then
		export PG_PACKAGE_$1=1
		ENABLED_PKG_ARR+=( $1 )
	else
		export PG_PACKAGE_$1=0
	fi
}

#check if value is enabled or disabled in setting.sh file
IsValueEnabled(){
        searchStr=$1
        varStatus=`cat settings.sh | grep -w $1 | cut -f 3 -d ' '`
        echo $varStatus
}
# Query if component is coupled
IsCoupled(){
        componentName=$1
        [[ ! " ${DECOUPLED_ARR[@]} " =~ " ${componentName} " ]] && return 0 || return 1;
}

#If the packages list is defined as 'all', then no need to set the config variables. settings.sh will take care of it.
if ! echo $PACKAGES | grep -w -i all > /dev/null
then
        for pkg in "${PACKAGES_ARR[@]}";
        do
                _set_config_package $pkg
        done
else
        for pkg in "${PACKAGES_ARR[@]}";
        do
                rValue=$(IsValueEnabled PG_PACKAGE_$pkg)
                if [[ $rValue == 1 ]]; then
                        ENABLED_PKG_ARR+=( $pkg )
                fi
        done
fi

# Run everything from the root of the buld directory
cd $DIRNAME

echo "#######################################################################" >> autobuild.log
echo "Build run starting at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log

#Get the date in the beginning to maintain consistency.
DATE=`date +'%Y-%m-%d'`

# Clear out any old output
echo "Cleaning up old output" >> autobuild.log
rm -rf output/* >> autobuild.log 2>&1

# Switch to REL-18 branch
echo "Switching to REL-18 branch" >> autobuild.log
git reset --hard >> autobuild.log 2>&1
git checkout REL-18 >> autobuild.log 2>&1

# Make sure, we always do a full build
if [ -f settings.sh.full.REL-18 ]; then
   cp -f settings.sh.full.REL-18 settings.sh
fi

# Self update
echo "Updating REL-18 branch build system" >> autobuild.log
git pull >> autobuild.log 2>&1

# Run the build, and dump the output to a log file
echo "Running the build (REL-18) " >> autobuild.log
./build.sh $SKIPBUILD 2>&1 | tee output/build-18.log

VERSION_NUMBER=`cat versions.sh | grep PG_MAJOR_VERSION= | cut -f 2 -d '='`
STR_VERSION_NUMBER=`echo $VERSION_NUMBER | sed 's/\.//'`

#-------------------
GetPkgDirName(){
        COMP_NAME=$1
        PACKAGES=${COMP_NAME,,}
        SERVER_VERSION=$STR_VERSION_NUMBER
        if ! (IsCoupled $COMP_NAME); then
                COMP_VERSION=`cat versions.sh | grep PG_VERSION_$COMP_NAME= | cut -f1,2 -d "." | cut -f 2 -d '='`
		if [[ $PACKAGES == *"languagepack"* ]]; then
                        COMP_VERSION=`cat versions.sh | grep PG_LP_VERSION= | cut -f1,2 -d "." | cut -f 2 -d '='`
                fi
                if [[ $COMP_VERSION == *"PG_MAJOR_VERSION"* ]]; then
                        COMP_VERSION_NUMBER=$SERVER_VERSION
                else
                        COMP_VERSION_NUMBER=$COMP_VERSION
                fi
                P_NAME=$PACKAGES/$COMP_VERSION_NUMBER
        else
                P_NAME=postgresql/$SERVER_VERSION
        fi
        echo ${P_NAME,,}
}

#------------------
GetInstallerName(){
        pkg_name=${1,,}
        if [[ $pkg_name == *"server"* ]]; then
                installerName=postgresql
        else
                installerName=$pkg_name
        fi
        echo ${installerName,,}
}

echo "#######################################################################" >> autobuild.log
echo "Build run completed at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log
echo "" >> autobuild.log
