#!/bin/bash

############################################################
#  Program:
#  Author :
############################################################
## BEGIN SCRIPT
Control_C()
{
  echo
  echo
  echo "Got Ctrl+C... Exiting..."
  echo "bye!"
  echo

  exit 0
}
 
# Trapping Interrupts
trap Control_C SIGINT


usage()
{
    cat << EOF

usage: $0 OPTIONS

OPTIONS can be:
    -h      Show this message
    -e      Using existing source
    -i      Install path
    -s      Path for the source tarballs
    -x      Don't build ncurses

------------------------------
-- Required Arguments
------------------------------
    -n      ncurses version
    -p      Python version
    -d      Python distrubute Setuptools version
    -P      Perl version
    -t      TCL/TK version
    -v      Language pack version
    -b      Server's installation path

EOF
}

MessageHeading()
{
    echo ""
    echo "-----------------------------------------------------"
    echo "$1"
    echo "-----------------------------------------------------"
}

# $1 - 0/1/2 - Info/Warning/Critical - Exit if critical error
# $2 - Message

export MSG_DEBUG=0
export MSG_INFO=1
export MSG_INFO_BIG=2
export MSG_WARN=3
export MSG_CRITICAL=4

Message()
{
    prefix="--> "

    case $1 in
        "$MSG_DEBUG")
            if [[ -n "$VERBOSE" ]];
            then
                prefix="$prefix [Debug]"
                echo "$prefix $2"
            fi
            ;;
        "$MSG_INFO")
            prefix="$prefix [Info]"
            echo "$prefix $2"
            ;;
        "$MSG_INFO_BIG")
            prefix="$prefix [Info]"
            echo
            echo "$prefix $2"
            echo
            ;;
        "$MSG_WARN")
            prefix="$prefix [Warning]"
            echo "$prefix $2"
            ;;
        "$MSG_CRITICAL")
            prefix="$prefix [Error]"

            MessageHeading "CRITICAL ERROR"

            echo "$prefix Script exiting because of the following error:"
            echo
            echo "$prefix $2"
            echo
            echo
            exit
            ;;
        ?)
            usage
            exit
            ;;
    esac
}

ExecuteCommand()
{
    Message $MSG_DEBUG "[Function: $FUNCNAME] Executing Command: $@"

    eval "$@"
    commandStatus=$?
    
    Message $MSG_DEBUG "[Function: $FUNCNAME] Command returned status: $commandStatus"

    if [[ $commandStatus -ne 0 ]]; then
        Message $MSG_CRITICAL "[Function: $FUNCNAME] Failed to execute command - \"$@\""
	exit 10
    fi
}

CheckRPMInstallation()
{
    strRPMName="$1"

    Message $MSG_INFO "Checking for RPM $strRPMName..."

    if [[ $(rpm -qa | grep -w $strRPMName | wc -l) -lt 1 ]]
    then
        Message $MSG_CRITICAL "Missing rpm $strRPMName"
        exit 1
    fi
}

DownlloadSource()
{
    ComponentName=$1
    ComponentVersion=$2
    DownloadURL=$3

    Message $MSG_INFO_BIG "[Downloading] $ComponentName $ComponentVersion..."
    ExecuteCommand "wget --progress=bar --no-check-certificate $DownloadURL"
}

# Show usage when there are no arguments.
if [[ -z "$1" ]]
then
    usage
    exit
fi

blnDownloadSource=1
blnBuildNCurses=1
source_path=
WD="$PWD"
install_path="$WD/languagepack/LanguagePack"    # Without / or - at the end...

PG_LANGUAGE_PACK_VERSION=
PG_VERSION_NCURSES=
PG_VERSION_PYTHON=
PG_VERSION_PERL=
PG_VERSION_TCL_TK=

PERL_INSTALL_PATH=
PYTHON_INSTALL_PATH=
TCL_TK_INSTALL_PATH=

PG_INSTALL_PATH=

# Check options passed in.
while getopts "hex i:n:p:d:P:s:t:v:b:" OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        e)
            blnDownloadSource=0
            ;;
        i)
            install_path=$OPTARG
            ;;
        n)
            PG_VERSION_NCURSES=$OPTARG
            NCURSES_INST="$WD/ncurses-$PG_VERSION_NCURSES/inst"

	    if [ "$PG_VERSION_NCURSES" == "0" ];
	    then
		blnBuildNCurses=0
	    fi
            ;;
        p)
            PG_VERSION_PYTHON=$OPTARG
            ;;
        d)
            PG_VERSION_PYTHON_SETUPTOOLS=$OPTARG
            ;;
        P)
            PG_VERSION_PERL=$OPTARG
            ;;
        s)
            SourcePath=$OPTARG
            ;;
        t)
            PG_VERSION_TCL_TK=$OPTARG
            ;;
        v)
            PG_LANGUAGE_PACK_VERSION=$OPTARG
            ;;
        b)
            PG_INSTALL_PATH=$OPTARG
            ;;
        x)
            blnBuildNCurses=0
            ;;
        ?)
            usage
            exit
            ;;
    esac
done

if [[ -z "$PG_VERSION_NCURSES" || -z "$PG_VERSION_TCL_TK" || -z "$PG_VERSION_PYTHON" || -z "$PG_VERSION_PERL" || -z "$PG_LANGUAGE_PACK_VERSION" || -z "$PG_INSTALL_PATH" || -z "$PG_VERSION_PYTHON_SETUPTOOLS" ]]
then
    usage
    exit 1
fi

if [[ -z "$SSL_INST" ]]
then
    Message $MSG_CRITICAL "ERROR: \$SSL_INST variable not set."
    exit 1
fi

if [[ -z "$install_path" ]]
then
    Message $MSG_CRITICAL "ERROR: Incorrect install path for language pack build."
    usage
    exit 1
fi


MessageHeading "Checking Required RPMs"

CheckRPMInstallation "chrpath"
CheckRPMInstallation "sqlite-devel"
CheckRPMInstallation "bzip2-devel"
CheckRPMInstallation "gdbm-devel"
CheckRPMInstallation "libX11-devel"
#CheckRPMInstallation "readline-devel"


NCURSES_LINK="http://ftp.gnu.org/gnu/ncurses/ncurses-$PG_VERSION_NCURSES.tar.gz"
##TCL_LINK="http://prdownloads.sourceforge.net/tcl/tcl$PG_VERSION_TCL_TK-src.tar.gz"
##TK_LINK="http://prdownloads.sourceforge.net/tcl/tk$PG_VERSION_TCL_TK-src.tar.gz"
TCL_LINK="ftp://ftp.tcl.tk/pub/tcl/tcl8.6/tcl$PG_VERSION_TCL_TK-src.tar.gz"
TK_LINK="ftp://ftp.tcl.tk/pub/tcl/tcl8.6/tk$PG_VERSION_TCL_TK-src.tar.gz"
PYTHON_LINK="https://www.python.org/ftp/python/$PG_VERSION_PYTHON/Python-$PG_VERSION_PYTHON.tgz"
PYTHON_SETUPTOOLS_LINK="https://pypi.python.org/packages/f1/92/12c7251039b274c30106c3e0babdcb040cbd13c3ad4b3f0ef9a7c217e36a/setuptools-$PG_VERSION_PYTHON_SETUPTOOLS.tar.gz"
PERL_LINK="http://www.cpan.org/src/5.0/perl-$PG_VERSION_PERL.tar.gz"


install_path="$install_path"

PERL_INSTALL_PATH="$install_path/Perl-$(echo $PG_VERSION_PERL | cut -d'.' -f1,2)"
PYTHON_INSTALL_PATH="$install_path/Python-$(echo $PG_VERSION_PYTHON | cut -d'.' -f1,2)"
TCL_TK_INSTALL_PATH="$install_path/Tcl-$(echo $PG_VERSION_TCL_TK | cut -d'.' -f1,2)"


MessageHeading "Downloading Sources"

if [ $blnDownloadSource -ne 0 ];
then
    rm -rf ncurses-$PG_VERSION_NCURSES*tar*
    rm -rf tcl$PG_VERSION_TCL_TK*tar*
    rm -rf tk$PG_VERSION_TCL_TK*tar*
    rm -rf Python-$PG_VERSION_PYTHON*tar*
    rm -rf setuptools-$PG_VERSION_PYTHON_SETUPTOOLS*tar*
    rm -rf perl-$PG_VERSION_PERL*tar*

    DownlloadSource "ncurses" "$PG_VERSION_NCURSES" "$NCURSES_LINK"
    DownlloadSource "TCL" "$PG_VERSION_TCL_TK" "$TCL_LINK"
    DownlloadSource "TK" "$PG_VERSION_TCL_TK" "$TK_LINK"
    DownlloadSource "Python" "$PG_VERSION_PYTHON" "$PYTHON_LINK"
    DownlloadSource "Python Setuptool " "$PG_VERSION_PYTHON_SETUPTOOLS" "$PYTHON_SETUPTOOLS_LINK"
    DownlloadSource "Perl" "$PG_VERSION_PERL" "$PERL_LINK"
else
    Message $MSG_INFO "Using existing sources..."
fi


MessageHeading "Building ncurses"

if [ $blnBuildNCurses -ne 0 ];
then
    rm -rf ncurses-$PG_VERSION_NCURSES

    ExecuteCommand "tar -zxvf ncurses-$PG_VERSION_NCURSES.tar.gz"

    Message $MSG_INFO_BIG "Building ncurses"

    ExecuteCommand "pushd ncurses-$PG_VERSION_NCURSES"
    ExecuteCommand "./configure --prefix=$NCURSES_INST --enable-widec --with-terminfo-dirs=/usr/share/terminfo --with-shared"
    ExecuteCommand "make"
    ExecuteCommand "make install"
    ExecuteCommand "popd"

    Message $MSG_INFO "Done..."
else
    Message $MSG_INFO "Using existing ncurses..."
fi


MessageHeading "Building TCL and TK"

if [ "$PG_VERSION_TCL_TK" != "0" ];
then
    rm -rf $TCL_TK_INSTALL_PATH
    rm -rf tcl$PG_VERSION_TCL_TK
    rm -rf tk$PG_VERSION_TCL_TK

    ExecuteCommand "tar -zxvf tcl$PG_VERSION_TCL_TK-src.tar.gz"

    Message $MSG_INFO_BIG "Building TCL..."

    ExecuteCommand "pushd tcl$PG_VERSION_TCL_TK/unix"
    (
        export LD_RUN_PATH=$TCL_TK_INSTALL_PATH/lib

        ExecuteCommand "CC='gcc -O2' ./configure  --prefix=$TCL_TK_INSTALL_PATH --enable-threads --enable-shared"
        ExecuteCommand "make"
        ExecuteCommand "make install"
    )

    ExecuteCommand "popd"

    Message $MSG_INFO "Done..."


    ExecuteCommand "tar -zxvf tk$PG_VERSION_TCL_TK-src.tar.gz"

    Message $MSG_INFO_BIG "Building TK..."

    ExecuteCommand "pushd tk$PG_VERSION_TCL_TK/unix"
    (
        export LD_RUN_PATH=$TCL_TK_INSTALL_PATH/lib

        ExecuteCommand "CC='gcc -O2' ./configure  --prefix=$TCL_TK_INSTALL_PATH --enable-threads --enable-shared"
        ExecuteCommand "make"
        ExecuteCommand "make install"

        Message $MSG_INFO_BIG "Setting RPATHs..."
        ExecuteCommand "pushd $TCL_TK_INSTALL_PATH"

        ExecuteCommand "pushd bin"
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs chmod 755 
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN/../lib" {}
        ExecuteCommand "popd"

        ExecuteCommand "pushd lib"
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs chmod 755 
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN" {}
        ExecuteCommand "popd"

        ExecuteCommand "popd"
    )

    ExecuteCommand "popd"

    Message $MSG_INFO "Done..."
fi


MessageHeading "Building Python"

if [ "$PG_VERSION_PYTHON" != "0" ];
then
    rm -rf $PYTHON_INSTALL_PATH
    rm -rf Python-$PG_VERSION_PYTHON
    rm -rf setuptools-$PG_VERSION_PYTHON_SETUPTOOLS
    rm -rf perl-$PG_VERSION_PERL

    ExecuteCommand "tar -zxvf Python-$PG_VERSION_PYTHON.tgz"
    
    #if [ "x$PG_LANGUAGE_PACK_VERSION" != "x9.0" -a "x$PG_LANGUAGE_PACK_VERSION" != "x9.1" -a "x$PG_LANGUAGE_PACK_VERSION" != "x9.4" ]
    #then
    #    ExecuteCommand "patch -p0 < Python_MAXREPEAT.patch"
    #fi
    
    ExecuteCommand "tar -zxvf setuptools-$PG_VERSION_PYTHON_SETUPTOOLS.tar.gz"

    Message $MSG_INFO_BIG "Building Python..."

    ExecuteCommand "pushd Python-$PG_VERSION_PYTHON"
    (
        export LDFLAGS="-L$NCURSES_INST/lib -L$SSL_INST/lib -L$TCL_TK_INSTALL_PATH/lib -lexpat"
        export CFLAGS="-I$NCURSES_INST/include/ncursesw -I$NCURSES_INST/include -I$SSL_INST/include -I$TCL_TK_INSTALL_PATH/include"
        export CPPFLAGS=$CFLAGS
        export LD_LIBRARY_PATH="$SSL_INST/lib:$TCL_TK_INSTALL_PATH/lib:$LD_LIBRARY_PATH"
        export LD_RUN_PATH="$PYTHON_INSTALL_PATH/lib"

        ExecuteCommand "CC='gcc -O2' ./configure  --prefix=$PYTHON_INSTALL_PATH --with-threads --enable-shared"
        ExecuteCommand "make"
        ExecuteCommand "make install"

    	Message $MSG_INFO_BIG "Copying OpenSSL libraries to Python installation..."
        ExecuteCommand "cp -rp $SSL_INST/lib/libssl.so* $PYTHON_INSTALL_PATH/lib"
        ExecuteCommand "cp -rp $SSL_INST/lib/libcrypto.so* $PYTHON_INSTALL_PATH/lib"

        Message $MSG_INFO_BIG "Copying TCL libraries to Python installation..."
        ExecuteCommand "cp -rp $TCL_TK_INSTALL_PATH/lib/libtcl* $PYTHON_INSTALL_PATH/lib"
        ExecuteCommand "cp -rp $TCL_TK_INSTALL_PATH/lib/libtk* $PYTHON_INSTALL_PATH/lib"
        ExecuteCommand "cp -rp $TCL_TK_INSTALL_PATH/lib/tcl8.6 $PYTHON_INSTALL_PATH/lib"
        ExecuteCommand "cp -rp $TCL_TK_INSTALL_PATH/lib/tk8.6 $PYTHON_INSTALL_PATH/lib"

        Message $MSG_INFO_BIG "Setting RPATHs..."
        ExecuteCommand "pushd $PYTHON_INSTALL_PATH"

        ExecuteCommand "pushd bin"
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs chmod 755 
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN/../lib" {}

	if [ "x$PG_LANGUAGE_PACK_VERSION" != "x9.0" -a "x$PG_LANGUAGE_PACK_VERSION" != "x9.1" ]
	then
        	ExecuteCommand "ln -sv python3 python"
	fi
        ExecuteCommand "popd"

        ExecuteCommand "pushd lib"
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs chmod 755 
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN" {}
        ExecuteCommand "popd"

        ExecuteCommand "popd"
    )

    ExecuteCommand "popd"

    Message $MSG_INFO_BIG "Building Python Setuptools..."
    ExecuteCommand "pushd setuptools-$PG_VERSION_PYTHON_SETUPTOOLS"
    (
    	export PYTHONHOME="$PYTHON_INSTALL_PATH"
        export PYTHONPATH="$PYTHON_INSTALL_PATH"
	export PATH="$PYTHON_INSTALL_PATH/bin:$PG_INSTALL_PATH/bin:$PATH"
	export LD_LIBRARY_PATH="$SSL_INST/lib:$LD_LIBRARY_PATH"
        ExecuteCommand "python setup.py install"
    	ExecuteCommand "easy_install pip"
	ExecuteCommand "pip3 install -r $PG_PATH_LINUX/../pem/requirements_py3.txt"
	ExecuteCommand "cp -rp $SSL_INST/lib/libjpeg* $PYTHON_INSTALL_PATH/lib"
	ExecuteCommand "cp -rp $SSL_INST/lib/libtiff* $PYTHON_INSTALL_PATH/lib"

	ExecuteCommand "pip3 list >$PYTHON_INSTALL_PATH/pip_packages_list.txt"
    )
    ExecuteCommand "popd"

    Message $MSG_INFO "Done..."
fi


MessageHeading "Building Perl"

if [ "$PG_VERSION_PERL" != "0" ];
then
    rm -rf $PERL_INSTALL_PATH
    rm -rf perl-$PG_VERSION_PERL

    ExecuteCommand "tar -zxvf perl-$PG_VERSION_PERL.tar.gz"

    Message $MSG_INFO_BIG "Building Perl..."

    ExecuteCommand "pushd perl-$PG_VERSION_PERL"
    (
        export LD_RUN_PATH=$PERL_INSTALL_PATH/lib
    
        ExecuteCommand "CC='gcc -O2 -D_REENTRANT -D_GNU_SOURCE -DUSE_SITECUSTOMIZE -DPERL_RELOCATABLE_INCPUSH -fno-merge-constants -fno-strict-aliasing -pipe -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64' \
                    ./Configure -ders -Dcc=gcc -Dusethreads -Duseithreads -Uinstallusrbinperl -Ulocincpth= -Uloclibpth= -Accflags=-DUSE_SITECUSTOMIZE -Duselargefiles \
                    -Accflags=-DPERL_RELOCATABLE_INCPUSH -Accflags=-fno-merge-constants -Dsed=/bin/sed -Duseshrplib \
                    -Dprefix=$PERL_INSTALL_PATH -Dprivlib=$PERL_INSTALL_PATH/lib -Darchlib=$PERL_INSTALL_PATH/lib \
                    -Dsiteprefix=$PERL_INSTALL_PATH/lib -Dsitelib=$PERL_INSTALL_PATH/lib -Dsitearch=$PERL_INSTALL_PATH/lib -Dextras=\"DBI DBD\""
        ExecuteCommand "make"
        ExecuteCommand "make install"


        Message $MSG_INFO_BIG "Setting RPATHs..."
        ExecuteCommand "pushd $PERL_INSTALL_PATH"

        ExecuteCommand "pushd bin"
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs chmod 755 
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN/../lib/CORE" {}
        ExecuteCommand "popd"

        ExecuteCommand "pushd lib"
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs chmod 755 
        find * -type f | xargs file | grep ELF | cut -f1 -d":" | xargs -I{} chrpath -r "\$ORIGIN" {}
        ExecuteCommand "popd"

        ExecuteCommand "popd"
    )

    ExecuteCommand "popd"

    Message $MSG_INFO "Done..."
fi

MessageHeading "Renaming Install Folders"
Message $MSG_INFO "Renaming folders..."

#ExecuteCommand "pushd $install_path"
#ExecuteCommand "ls | xargs -I{} echo \"mv -v {} \\\$(echo \"{}\" | cut -d'.' -f1,2)\" | sh"
#ExecuteCommand "popd"

MessageHeading "Completed!"

Message $MSG_INFO "SSL Path: $SSL_INST"

Message $MSG_INFO "ncurses: $PG_VERSION_NCURSES"
Message $MSG_INFO "TCL: $PG_VERSION_TCL_TK"
Message $MSG_INFO "TK: $PG_VERSION_TCL_TK"
Message $MSG_INFO "Python: $PG_VERSION_PYTHON"
Message $MSG_INFO "Perl: $PG_VERSION_PERL"

Message $MSG_INFO "Language pack builds at: $install_path"

