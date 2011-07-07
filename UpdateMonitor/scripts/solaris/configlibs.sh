#!/bin/bash

# PostgreSQL startup configuration script for Linux
# Ashesh Vashi, EnterpriseDB

_process_libs() {

  lib_dir=$1
  libname=$2
  
  # Remove the libraries that are already present in the system.
  cd $lib_dir
  library_list=`find . -name "$libname*"`
  standard_lib64_path="/lib64 /usr/lib64 /usr/local/lib64"
  standard_lib_path="/lib /usr/lib /usr/local/lib"

  for library in $library_list
  do
    found_at_dir=
    flag=
    library=`basename $library`  
    if [ -d "/lib64" ]; then 
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
_process_libs "INSTALL_DIR/lib" "libQtXml.so"
_process_libs "INSTALL_DIR/lib" "libQtCore.so"
_process_libs "INSTALL_DIR/lib" "libQtNetwork.so"
_process_libs "INSTALL_DIR/lib" "libQtGui.so"

