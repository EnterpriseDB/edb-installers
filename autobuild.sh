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

# Switch to REL-9_2 branch
echo "Switching to REL-9_2 branch" >> autobuild.log
git reset --hard >> autobuild.log 2>&1
git checkout REL-9_2 >> autobuild.log 2>&1

# Make sure, we always do a full build
if [ -f settings.sh.full.REL-9_2 ]; then
   cp -f settings.sh.full.REL-9_2 settings.sh
fi

# Self update
echo "Updating REL-9_2 branch build system" >> autobuild.log
git pull >> autobuild.log 2>&1

# Run the build, and dump the output to a log file
echo "Running the build (REL-9_2) " >> autobuild.log
./build.sh > output/build-92.log 2>&1

_mail_status "build-92.log" "9.2"

# Create a remote directory and upload the output.
echo "Creating /var/www/html/builds/pgInstaller/$DATE/9.2 on the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com mkdir -p /var/www/html/builds/pgInstaller/$DATE/9.2 >> autobuild.log 2>&1

echo "Uploading output to /var/www/html/builds/pgInstaller/$DATE/9.2 on the builds server" >> autobuild.log
scp output/* buildfarm@builds.enterprisedb.com:/var/www/html/builds/pgInstaller/$DATE/9.2 >> autobuild.log 2>&1

echo "#######################################################################" >> autobuild.log
echo "Build run completed at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log
echo "" >> autobuild.log
