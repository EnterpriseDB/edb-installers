#!/bin/sh
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved

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
_process_libs "INSTALL_DIR/lib" "libssl.so"
_process_libs "INSTALL_DIR/lib" "libcrypto.so"
_process_libs "INSTALL_DIR/lib" "libQtXml.so"
_process_libs "INSTALL_DIR/lib" "libQtCore.so"
_process_libs "INSTALL_DIR/lib" "libQtNetwork.so"
_process_libs "INSTALL_DIR/lib" "libQtGui.so"
_process_libs "INSTALL_DIR/lib" "libpng12.so"
_process_libs "INSTALL_DIR/lib" "libexpat.so"
_process_libs "INSTALL_DIR/lib" "libgssapi_krb5.so"
_process_libs "INSTALL_DIR/lib" "libkrb5.so"
_process_libs "INSTALL_DIR/lib" "libcom_err.so"
_process_libs "INSTALL_DIR/lib" "libk5crypto.so"
_process_libs "INSTALL_DIR/lib" "libjpeg.so"
_process_libs "INSTALL_DIR/lib" "libtiff.so"
_process_libs "INSTALL_DIR/lib" "libz.so"
_process_libs "INSTALL_DIR/lib" "libfreetype.so"
_process_libs "INSTALL_DIR/lib" "libfontconfig.so"
_process_libs "INSTALL_DIR/lib" "libpangoft2-1.0.so"
_process_libs "INSTALL_DIR/lib" "libpangoxft-1.0.so"
_process_libs "INSTALL_DIR/lib" "libpangox-1.0.so"
_process_libs "INSTALL_DIR/lib" "libpango-1.0.so"

