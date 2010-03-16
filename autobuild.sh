#!/bin/sh

# pgInstaller auto build script
# Dave Page, EnterpriseDB

# Any changes to this file should be made to all the git branches.

if [ $# -ne 1 ]; 
then
    echo "Usage: $0 <build dir>"
    exit 127
fi

# Run everything from the root of the buld directory
cd $1

echo "#######################################################################" >> autobuild.log
echo "Build run starting at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log

# Clear out any old output
echo "Cleaning up old output" >> autobuild.log
rm -rf output/* >> autobuild.log 2>&1

# Switch to REL-9_0_DEV branch
echo "Switching to REL-9_0_DEV branch" >> autobuild.log
/opt/local/bin/git checkout REL-9_0_DEV >> autobuild.log 2>&1

# Self update
echo "Updating build system" >> autobuild.log
/opt/local/bin/git pull >> autobuild.log 2>&1

# Make sure, we always do a full build
if [ -f settings.sh.full ]; then
   cp -f setttings.sh.full settings.sh
fi

# Run the build, and dump the output to a log file
echo "Running the build" >> autobuild.log
./build.sh > output/build-90.log 2>&1

echo "Purging old builds from the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com "bin/culldirs \"/var/www/html/builds/pgInstaller/*-*-*\" 2" >> autobuild.log 2>&1

# Create a remote directory and upload the output.
DATE=`date +'%Y-%m-%d'`
echo "Creating /var/www/html/builds/pgInstaller/$DATE/9.0 on the builds server" >> autobuild.log
ssh buildfarm@builds.enterprisedb.com mkdir -p /var/www/html/builds/pgInstaller/$DATE/9.0 >> autobuild.log 2>&1

echo "Uploading output to /var/www/html/builds/pgInstaller/$DATE/9.0 on the builds server" >> autobuild.log
scp output/* buildfarm@builds.enterprisedb.com:/var/www/html/builds/pgInstaller/$DATE/9.0 >> autobuild.log 2>&1

echo "#######################################################################" >> autobuild.log
echo "Build run completed at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log
echo "" >> autobuild.log
