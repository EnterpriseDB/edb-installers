#!/bin/sh
# Copyright (c) 2012-2015, EnterpriseDB Corporation.  All rights reserved
# postgreSQL startup configuration script for Linux
echo "executing $0"

INSTALL_DIR="$1"

_split()
{
    # Prefix local names with the function name to try to avoid conflicts
    # local split_wordlist
    split_wordlist="$1"
    shift
    read "$@" <<EOF-split-end-of-arguments
${split_wordlist}
EOF-split-end-of-arguments
}

# Usage: version_compare v1 v2
# Where v1 and v2 are multi-part version numbers such as 12.5.67
# Missing .<number>s on the end of a version are treated as .0, & leading
# zeros are not significant, so 1.2 == 1.2.0 == 1.2.0.0 == 01.2 == 1.02
# Returns true if v1 >= v2, false if v1 < v2
_version_compare()
{
    # Prefix local names with the function name to try to avoid conflicts
    # local version_comp_1 version_comp_2 version_comp_a version_comp_b
    # local version_comp_save_ifs
    version_comp_v1="$1"
    version_comp_v2="$2"

    version_comp_save_ifs="$IFS"
    while test -n "${version_comp_v1}${version_comp_v2}"; do
        IFS="."
        _split "$version_comp_v1" version_comp_a version_comp_v1
        _split "$version_comp_v2" version_comp_b version_comp_v2
        IFS="$version_comp_save_ifs"
        #echo " compare  $version_comp_a  $version_comp_b"
        #test "0$version_comp_a" -gt "0$version_comp_b" && return 1 # v1>v2: true
        #test "0$version_comp_a" -lt "0$version_comp_b" && return 2 # v1<v2:false

        if [ "0$version_comp_a" \> "0$version_comp_b" ]; then
                 return 2 # Greater then
        fi
        if [ "0$version_comp_a" \< "0$version_comp_b" ]; then
                return 1 # Less then
        fi
    done
    return 0 # Equal
}

_process_libs() {
    install_libdir=$1
    install_libname=$2
    install_libabpath="${install_libdir}/${install_libname}"

    install_liblist=`find $install_libdir -name "${install_libname}*" -type f`
    if [ "$install_liblist" = "" ]; then
       echo "WARNING: $install_libname is not found in $install_libdir"
       return
    fi

    for install_list_name in $install_liblist
    do
          #Check if the lib is installed or not.
	  syslib_soname=`/sbin/ldconfig -p | grep "$install_libname" | awk '{print $NF}' `
          if [ "$syslib_soname" != "" ]; then 
               #Check if this is a softlink or not, if yes that the syslib
	       syslib=`readlink $syslib_soname`
	       if [ "$syslib" != "" ]; then
			_cleanup_libs $syslib $install_list_name $install_libabpath
			break;
		fi
	fi
  done
}



_cleanup_libs() {
	syslib=$1
	install_lib_name=$2
	install_libabpath=$3

	_version_compare $syslib `basename $install_lib_name`
	out=$?

	#If version of the system lib are equal or greater than user installed lib version then remove
	#if version of the system lib are lesser then donot remove the user installed libs
	if [ $out = 0 ] || [ $out = 2 ]; then
		echo "DEL: Library $install_lib_name already found in system"
		echo "---- rm -rf ${install_libabpath}*"
		rm -rf "${install_libabpath}"*
	fi 

}

# Process server libs
_process_libs "$INSTALL_DIR/lib" "libpangocairo-1.0.so"
_process_libs "$INSTALL_DIR/lib" "libpangoft2-1.0.so"
_process_libs "$INSTALL_DIR/lib" "libpango-1.0.so"
_process_libs "$INSTALL_DIR/pgAdmin3/lib" "libfreetype.so"
