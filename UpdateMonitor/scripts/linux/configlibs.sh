#!/bin/sh

# PostgreSQL startup configuration script for Linux
# Ashesh Vashi, EnterpriseDB

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
_process_libs "INSTALL_DIR/lib" "libQtXml.so"
_process_libs "INSTALL_DIR/lib" "libQtCore.so"
_process_libs "INSTALL_DIR/lib" "libQtNetwork.so"
_process_libs "INSTALL_DIR/lib" "libQtGui.so"

