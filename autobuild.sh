#!/bin/sh

# pgInstaller auto build script
# Dave Page, EnterpriseDB

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

# Self update
echo "Updating build system" >> autobuild.log
git pull >> autobuild.log 2>&1

# Run the build, and dump the output to a log file
echo "Running the build" >> autobuild.log
./build.sh > output/build.log 2>&1

# Create a remote directory and upload the output.
DATE=`date +'%Y-%m-%d'`
echo "Creating pub/pgInstaller/$DATE on the sftp server" >> autobuild.log
ssh dpage@sftp.enterprisedb.com mkdir -p pub/pgInstaller/$DATE >> autobuild.log 2>&1

echo "Uploading output to pub/pgInstaller/$DATE on the sftp server" >> autobuild.log
scp output/* dpage@sftp.enterprisedb.com:pub/pgInstaller/$DATE >> autobuild.log 2>&1

echo "Purging old builds from the sftp server" >> autobuild.log
ssh dpage@sftp.enterprisedb.com "bin/culldirs \"pub/pgInstaller/*-*-*\" 3" >> autobuild.log 2>&1

echo "#######################################################################" >> autobuild.log
echo "Build run completed at `date`" >> autobuild.log
echo "#######################################################################" >> autobuild.log
echo "" >> autobuild.log
