#!/bin/bash

# Check the command line
if [ $# -ne 1 ];
then
    echo "Usage: $0 <Install dir>"
    exit 127
fi

INSTALLDIR=$1

_process_libs() {

  lib_dir=$1
  libname=$2

  # Remove the libraries that are already present in the system.
  cd $lib_dir	
  library_list=`ls $libname*`

  for library in $library_list
  do
     if [ -d "/lib64" ]
     then
       flag1=`ls /lib64/$library`
     else
       flag1=`ls /lib/$library`
     fi
     if [ -d "/usr/lib64" ]
     then
       flag2=`ls /usr/lib64/$library`
     else
       flag2=`ls /usr/lib/$library`
     fi
     # If found delete the library from the INSTALLDIR/lib 
     if [ "x$flag1" != "x" -o "y$flag2" != "y" ]
     then
           rm -f $library   || _die "Failed to remove the library $library"
     fi
  done

}

# Process Dependent libs
_process_libs  "$INSTALLDIR/lib" "libssl.so"
_process_libs  "$INSTALLDIR/lib" "libcrypto.so"
_process_libs  "$INSTALLDIR/lib" "libcom_err.so"
_process_libs  "$INSTALLDIR/lib" "libgssapi_krb5.so"
_process_libs  "$INSTALLDIR/lib" "libkrb5.so"
_process_libs  "$INSTALLDIR/lib" "libk5crypto.so"

