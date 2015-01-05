#!/bin/bash
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

PGHOME=$1

#Copying the lib files to pkglibdir
libdir=`$PGHOME/bin/pg_config --pkglibdir`
mv -f $PGHOME/lib/slony1_funcs*.so $libdir/

#Copying the share files to sharedir
sharedir=`$PGHOME/bin/pg_config --sharedir`

#Creating file removal scripts to run at the time of uninstallation
filelist=`ls $PGHOME/share/Slony/`
echo "#!/bin/bash" > $PGHOME/Slony/installer/Slony/removeFiles.sh
echo "#Remove these files installed in the lib directory" >> $PGHOME/Slony/installer/Slony/removeFiles.sh
echo "rm -rf $libdir/slony1_funcs*.so" >> $PGHOME/Slony/installer/Slony/removeFiles.sh
echo "#Remove these files installed in the share directory" >> $PGHOME/Slony/installer/Slony/removeFiles.sh
for f in $filelist
do
   echo "rm -rf $sharedir/$f" >> $PGHOME/Slony/installer/Slony/removeFiles.sh
done
chmod ugo+x $PGHOME/Slony/installer/Slony/removeFiles.sh

mv -f $PGHOME/share/Slony/* $sharedir/
rm -rf $PGHOME/share/Slony


