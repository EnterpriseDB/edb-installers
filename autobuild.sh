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

# Switch to master branch
echo "Switching to master branch" >> autobuild.log
/opt/local/bin/git checkout master >> autobuild.log 2>&1

# Self update
echo "Updating build system" >> autobuild.log
/opt/local/bin/git pull >> autobuild.log 2>&1

# Make sure, we always do a full build
if [ -f settings.sh.full ]; then
   cp -f setttings.sh.full settings.sh
fi

# Run the build, and dump the output to a log file
echo "Running the build" >> autobuild.log
./build.sh > output/build-84.log 2>&1

# Switch to REL-8_3 branch
echo "Switching to REL-8_3 branch" >> autobuild.log
/opt/local/bin/git checkout REL-8_3 >> autobuild.log 2>&1

# Self update
echo "Updating REL-8_3 branch build system" >> autobuild.log
/opt/local/bin/git pull >> autobuild.log 2>&1

# Run the build, and dump the output to a log file
echo "Running the build (REL-8_3) " >> autobuild.log
./build.sh >> output/build-83.log 2>&1

# Create a remote directory and upload the output.
DATE=`date +'%Y-%m-%d'`
echo "Creating /mnt/storage/pgInstaller/$DATE on the store server" >> autobuild.log
ssh dave.page@store.nj.us.enterprisedb.com mkdir -p /mnt/storage/pgInstaller/$DATE >> autobuild.log 2>&1

echo "Uploading output to pub/pgInstaller/$DATE on the store server" >> autobuild.log
scp output/* dave.page@store.nj.us.enterprisedb.com:/mnt/storage/pgInstaller/$DATE >> autobuild.log 2>&1

echo "Purging old builds from the store server" >> autobuild.log
ssh dave.page@store.nj.us.enterprisedb.com "bin/culldirs \"/mnt/storage/pgInstaller/*-*-*\" 3" >> autobuild.log 2>&1

echo "#######################################################################" >> autobuild.log
echo "Build run completed at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log
echo "" >> autobuild.log
