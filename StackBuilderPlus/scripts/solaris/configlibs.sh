#!/bin/bash
# Copyright (c) 2012-2014, EnterpriseDB Corporation.  All rights reserved

# For Solaris

_process_libs() {

  lib_dir=$1
  libname=$2
  
  # Remove the libraries that are already present in the system.
  cd $lib_dir
  library_list=`find . -name "$libname*"`
  standard_lib64_path="/lib/64 /usr/lib/64 /usr/sfw/lib/64"
  standard_lib_path="/lib /usr/lib /usr/sfw/lib"

  for library in $library_list
  do
    found_at_dir=
    flag=
    library=`basename $library`  
    if [ -d "/lib/64" ]; then 
      for stdlibdir in $standard_lib64_path
      do
        if [ x"$flag" = x"" ]
        then
          flag=`ls $stdlibdir/$library`
          found_at_dir=$flag
        else
          break
        fi
      done
    else
      for stdlibdir in $standard_lib_path
      do
        if [ "x$flag" = "x" ]
        then
          flag=`ls $stdlibdir/$library`
          found_at_dir=$stdlibdir
        else
          break
        fi
      done
    fi

    # If found delete the library from the INSTALLDIR/lib 
    if [ x"$flag" != x"" ]
    then
      echo "NOTE: Found '$library' in '$found_at_dir' on the system"
      echo "      Removing it from the '$lib_dir'."
      rm -f $library || _die "Failed to remove the library $library"
    fi
  done

}

# Process server libs
_process_libs "INSTALL_DIR/lib" "libssl.so.1.0.0"
_process_libs "INSTALL_DIR/lib" "libcrypto.so.1.0.0"
_process_libs "INSTALL_DIR/lib" "libQtXml.so.4.4.3"
_process_libs "INSTALL_DIR/lib" "libQtCore.so.4.4.3"
_process_libs "INSTALL_DIR/lib" "libQtNetwork.so.4.4.3"
_process_libs "INSTALL_DIR/lib" "libQtGui.so.4.4.3"
_process_libs "INSTALL_DIR/lib" "libpng15.so.0"
_process_libs "INSTALL_DIR/lib" "libexpat.so"
_process_libs "INSTALL_DIR/lib" "libgssapi_krb5.so.2.2"
_process_libs "INSTALL_DIR/lib" "libkrb5.so.3.3"
_process_libs "INSTALL_DIR/lib" "libcom_err.so.3.0"
_process_libs "INSTALL_DIR/lib" "libk5crypto.so.3.1"
_process_libs "INSTALL_DIR/lib" "libjpeg.so.8.4.0"
_process_libs "INSTALL_DIR/lib" "libtiff.so.5.0.6"
_process_libs "INSTALL_DIR/lib" "libz.so.1.2.7"
_process_libs "INSTALL_DIR/lib" "libfreetype.so.6.3.7"
_process_libs "INSTALL_DIR/lib" "libfontconfig.so.1"
_process_libs "INSTALL_DIR/lib" "libpangoft2-1.0.so"
_process_libs "INSTALL_DIR/lib" "libpangoxft-1.0.so"
_process_libs "INSTALL_DIR/lib" "libpangox-1.0.so"
_process_libs "INSTALL_DIR/lib" "libpango-1.0.so"

