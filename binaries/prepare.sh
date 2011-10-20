#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/opt/local/bin

#Determine which distros to prepare
. ./distro_settings.sh

#CM folder name
cm_dirname=autobuild
echo $cmd_dirname
ftplocation=ftp://mail.isb.pk.enterprisedb.com/Binaries/as91-binaries-for-installer/$cm_dirname
echo $ftplocation

#Move existing .tar.gz to a folder
dirname=$(date +"%d%m%y-%H%M")
mkdir ./$dirname
if [ $PREP_HPUX = 1 ]; then
  mv ./AS91-HPUX-shared.tar.gz ./$dirname/
  wget "$ftplocation/AS91-HPUX-shared.tar.gz"

  # Make sure the download went okay.
  if [ $? -ne 0 ]
  then
      # wget had problems.
      echo "Wget has errors fetching HPUX distro."
      exit 1 
  fi
  rm -rf ./AS91-HPUX
  if [ -f ./AS91-HPUX-shared.tar.gz ]; then
    tar -xvzf ./AS91-HPUX-shared.tar.gz
  else
    echo "File missing: AS91-HPUX-shared.tar.gz"
    exit 1
  fi
fi

#set permissions
#./permissions.sh

exit 0
