#!/bin/sh

# pgInstaller auto build script
# Dave Page, EnterpriseDB

BASENAME=`basename $0`
DIRNAME=`dirname $0`

# Any changes to this file should be made to all the git branches.

usage()
{
        echo "Usage: $BASENAME [Options]\n"
        echo "    Options:"
        echo "      [-skipbuild boolean]" boolean value may be either "1" or "0"
        echo "      [-platforms list]  list of platforms. It may include the list of supported platforms separated by comma or all" 
        echo "      [-packages list]   list of packages. It may include the list of supported platforms separated by comma or all"
        echo "    Examples:"
        echo "     $BASENAME -skipbuild 0 -platforms "linux, linux_64, windows, windows_x64, osx" -packages "server, apachephp, phppgadmin, pgjdbc, psqlodbc, slony, postgis, npgsql, pgagent, pgmemcache, pgbouncer, migrationtoolkit, replicationserver, plpgsqlo, sqlprotect, update_monitor""
        echo "     $BASENAME -skipbuild 1 -platforms "all" -packages "all""
        echo ""
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
                -help|-h) usage;;
                *) echo -e "error: no such option $1. -h for help"; exit 1;;
        esac
done

# platforms variable value cannot be empty.
if [ "$PLATFORMS" = "" ]
then
        echo "Error: Please specify the platforms list"
        exit 2
fi

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
	else
	     export PG_PACKAGE_$1=0
        fi
}

_set_config_platform()
{
	if echo $PLATFORMS | grep -w -i $1 > /dev/null
        then
             export PG_ARCH_$1=1
	else
	     export PG_ARCH_$1=0
        fi
}

#If the platforms list is defined as 'all', then no need to set the config variables. settings.sh will take care of it.
if ! echo $PLATFORMS | grep -w -i all > /dev/null
then
_set_config_platform LINUX
_set_config_platform LINUX_X64
_set_config_platform OSX
_set_config_platform WINDOWS
_set_config_platform WINDOWS_X64
fi

#If the packages list is defined as 'all', then no need to set the config variables. settings.sh will take care of it.
if ! echo $PACKAGES | grep -w -i all > /dev/null
then
_set_config_package SERVER
_set_config_package APACHEPHP
_set_config_package PHPPGADMIN
_set_config_package PGJDBC
_set_config_package PSQLODBC
_set_config_package POSTGIS
_set_config_package SLONY
_set_config_package NPGSQL
_set_config_package PGAGENT
_set_config_package PGMEMCACHE
_set_config_package PGBOUNCER
_set_config_package MIGRATIONTOOLKIT
_set_config_package REPLICATIONSERVER
_set_config_package PLPGSQLO
_set_config_package SQLPROTECT
_set_config_package UPDATE_MONITOR
fi

# Generic mail variables
log_location="/Users/buildfarm/pginstaller_2.auto/output"
header_fail="Autobuild failed with the following error (last 20 lines of the log):
###################################################################################"
footer_fail="###################################################################################"

# Mail function
_mail_status()
{
        filename=$1
	version=$2
        log_file=$log_location/$filename

        log_content=`tail -20 $log_file`
        error_flag=`echo $log_content | grep "FATAL ERROR"`
        if [ "x$error_flag" = "x" ];
        then
                mail_content="Autobuild completed Successfully."
                build_status="SUCCESS"
                mail_receipents="sandeep.thakkar@enterprisedb.com"
        else
                mail_content="
$header_fail

$log_content

$footer_fail"
                build_status="FAILED"
                mail_receipents="pginstaller@enterprisedb.com"
        fi

        mail -s "pgInstaller Build $version - $build_status" $mail_receipents <<EOT
$mail_content
EOT
}

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

# Switch to REL-9_3 branch
echo "Switching to REL-9_3 branch" >> autobuild.log
git reset --hard >> autobuild.log 2>&1
git checkout REL-9_3 >> autobuild.log 2>&1

# Make sure, we always do a full build
if [ -f settings.sh.full.REL-9_3 ]; then
   cp -f settings.sh.full.REL-9_3 settings.sh
fi

# Self update
echo "Updating REL-9_3 branch build system" >> autobuild.log
git pull >> autobuild.log 2>&1

# Run the build, and dump the output to a log file
echo "Running the build (REL-9_3) " >> autobuild.log
./build.sh $SKIPBUILD 2>&1 | tee output/build-93.log

_mail_status "build-93.log" "9.3"

remote_location="/var/www/html/builds/Installers"

# Different location for the manual and cron triggered builds.
if [ "$BUILD_USER" == "" ]
then
        remote_location="$remote_location/$DATE/9.3"
else
        remote_location="$remote_location/Custom/$BUILD_USER/9.3/$BUILD_NUMBER"
fi

# Create a remote directory and upload the output.
echo "Creating $remote_location on the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com mkdir -p $remote_location >> autobuild.log 2>&1

echo "Uploading output to $remote_location on the builds server" >> autobuild.log
scp output/* buildfarm@builds.enterprisedb.com:$remote_location >> autobuild.log 2>&1

echo "#######################################################################" >> autobuild.log
echo "Build run completed at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log
echo "" >> autobuild.log
