#! /bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/opt/local/bin

. ./distro_settings.sh

if [ $PREP_HPUX = 1 ]; then
 #Mark all files except bin folder as 644 (rw-r--r--)
 find ./AS92-HPUX -type f -not -regex '.*/bin/*.*' -exec chmod 644 {} \;

 #Mark all sh with 755 (rwxr-xr-x)
 find ./AS92-HPUX -name \*.sh -exec chmod 755 {} \;

 #Mark all directories with 755(rwxr-xr-x)
 find ./AS92-HPUX -type d -exec chmod 755 {} \;
fi
