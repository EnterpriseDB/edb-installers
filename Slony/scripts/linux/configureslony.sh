#!/bin/bash

PGHOME=$1

#Copying the lib files to pkglibdir
libdir=`$PGHOME/bin/pg_config --pkglibdir`
mv -f $PGHOME/lib/slony1_funcs.so $libdir/
mv -f $PGHOME/lib/xxid.so $libdir/

#Copying the share files to sharedir
sharedir=`$PGHOME/bin/pg_config --sharedir`
mv -f $PGHOME/share/Slony/* $sharedir/
rm -rf $PGHOME/share/Slony


