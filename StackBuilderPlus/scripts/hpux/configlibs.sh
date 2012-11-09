#!/bin/sh
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved

# PostgreSQL startup configuration script for Linux

_process_libs() {

  lib_dir=$1
  libname=$2
  platform=@@PLATFORM@@   
  
  # Remove the libraries that are already present in the system.
  cd $lib_dir
  library_list=`find . -name "$libname*"`
  standard_lib64_path="/lib64 /usr/lib64 /usr/local/lib64"
  standard_lib32_path="/lib /usr/lib /usr/local/lib"

  if [ $platform = "linux64" ]; then
    standard_lib_path=$standard_lib64_path
  else
    standard_lib_path=$standard_lib32_path
  fi
  
  for library in $library_list
  do
    lib=`basename $library`  
    for stdlibdir in $standard_lib_path
    do
      if [ -e $stdlibdir/$lib ]; then
        echo "NOTE: Found '$lib' in '$stdlibdir' on the system"
        echo "      Removing it from the '$lib_dir'."
        rm -f $lib_dir/$lib || _die "Failed to remove the library $library"
        break
      fi
    done
  done

}

# Process server libs
_process_libs "INSTALL_DIR/lib" "libssl.so.1.0.0"
_process_libs "INSTALL_DIR/lib" "libcrypto.so.1.0.0"
_process_libs "INSTALL_DIR/lib" "libQtXml.so.4.8.1"
_process_libs "INSTALL_DIR/lib" "libQtCore.so.4.8.1"
_process_libs "INSTALL_DIR/lib" "libQtNetwork.so.4.8.1"
_process_libs "INSTALL_DIR/lib" "libQtGui.so.4.8.1"
_process_libs "INSTALL_DIR/lib" "libpng12.so.0"
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
