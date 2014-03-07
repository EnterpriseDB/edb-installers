#!/bin/sh

# pgInstaller auto build script
# Dave Page, EnterpriseDB

# Any changes to this file should be made to all the git branches.

if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <build dir>"
    exit 127
fi

# Generic mail variables
log_location="/Users/buildfarm/pginstaller.auto/output"
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
cd $1

echo "#######################################################################" >> autobuild.log
echo "Build run starting at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log

#Get the date in the beginning to maintain consistency.
DATE=`date +'%Y-%m-%d'`

# Clear out any old output
echo "Cleaning up old output" >> autobuild.log
rm -rf output/* >> autobuild.log 2>&1

# Switch to REL-9_0 branch
echo "Switching to REL-9_0 branch" >> autobuild.log
/opt/local/bin/git reset --hard >> autobuild.log 2>&1
/opt/local/bin/git checkout REL-9_0 >> autobuild.log 2>&1

# Self update
echo "Updating build system" >> autobuild.log
/opt/local/bin/git reset --hard >> autobuild.log 2>&1
/opt/local/bin/git pull >> autobuild.log 2>&1

# Make sure, we always do a full build
if [ -f settings.sh.full.REL-9_0 ]; then
   cp -f settings.sh.full.REL-9_0 settings.sh
fi

# Run the build, and dump the output to a log file
echo "Running the build" >> autobuild.log
./build.sh > output/build-90.log 2>&1

_mail_status "build-90.log" "9.0"

remote_location="/var/www/html/builds/DailyBuilds/Installers/PG"

echo "Purging old builds from the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com "bin/culldirs "$remote_location/20*" 5" >> autobuild.log 2>&1

# remote location
remote_location_90="$remote_location/$DATE/9.0"

# Create a remote directory and upload the output.
echo "Creating $remote_location_90 on the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com mkdir -p $remote_location_90 >> autobuild.log 2>&1

echo "Uploading output to $remote_location_90 on the builds server" >> autobuild.log
scp output/* buildfarm@builds.enterprisedb.com:$remote_location_90 >> autobuild.log 2>&1

# Clear out 9.0 output
echo "Cleaning up 9.0 output" >> autobuild.log
rm -rf output/* >> autobuild.log 2>&1

# Switch to REL-9_1 branch
echo "Switching to REL-9_1 branch" >> autobuild.log
/opt/local/bin/git reset --hard >> autobuild.log 2>&1
/opt/local/bin/git checkout REL-9_1 >> autobuild.log 2>&1

# Make sure, we always do a full build
if [ -f settings.sh.full.REL-9_1 ]; then
   cp -f settings.sh.full.REL-9_1 settings.sh
fi

# Self update
echo "Updating REL-9_1 branch build system" >> autobuild.log
/opt/local/bin/git pull >> autobuild.log 2>&1

# Run the build, and dump the output to a log file
echo "Running the build (REL-9_1) " >> autobuild.log
./build.sh > output/build-91.log 2>&1

_mail_status "build-91.log" "9.1"

# remote location
remote_location_91="$remote_location/$DATE/9.1"

# Create a remote directory and upload the output.
echo "Creating $remote_location_91 on the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com mkdir -p $remote_location_91 >> autobuild.log 2>&1

echo "Uploading output to $remote_location_91 on the builds server" >> autobuild.log
scp output/* buildfarm@builds.enterprisedb.com:$remote_location_91 >> autobuild.log 2>&1

echo "#######################################################################" >> autobuild.log
echo "Build run completed at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log
echo "" >> autobuild.log
