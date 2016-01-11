#!/bin/sh
# Copyright (c) 2012-2016, EnterpriseDB Corporation.  All rights reserved

PG_INSTALLDIR=$1
source $PG_INSTALLDIR/etc/sysconfig/plLanguages.config

export PATH_PL_LANGUAGES=
export LD_LIBRARY_PATH_PL_LANGUAGES=

LoadPLPaths()
{
	LoadPerlPath 1
	LoadPythonPath 1
	LoadTclPath 1
}

VerifyPLPaths()
{
        LoadPerlPath 0
        LoadPythonPath 0
        LoadTclPath 0
}

LoadPerlPath()
{
	PERL_PATH_STRING=`cat $PG_INSTALLDIR/etc/sysconfig/plLanguages.config | grep PERL_INSTALL_PATH`

        if [ "x$PERL_PATH_STRING" == "x" ]; then

		if [ -f $PG_PERL_PATH/bin/perl ];then
                      PERL_VERSION=`$PG_PERL_PATH/bin/perl -version | grep $PG_PERL_VERSION`
		fi

                if [ "x$PERL_VERSION" == "x" ]; then
                      echo "INFO --> Required Perl version $PG_PERL_VERSION not found ..."
                else
                      echo "INFO --> Required Perl version $PG_PERL_VERSION found at $PG_PERL_PATH ..."

		      if [ "$1" == "1" ]; then
		                PATH_PL_LANGUAGES=$PG_PERL_PATH/bin:$PATH_PL_LANGUAGES
		                LD_LIBRARY_PATH_PL_LANGUAGES=$PG_PERL_PATH/lib/CORE:$LD_LIBRARY_PATH_PL_LANGUAGES
		      fi
                fi
        else
                echo "WARNING --> PERL_INSTALL_PATH is not set in $PG_INSTALLDIR/etc/sysconfig/plLanguages.config file"
        fi
}

LoadPythonPath()
{
        PYTHON_PATH_STRING=`cat $PG_INSTALLDIR/etc/sysconfig/plLanguages.config | grep PYTHON_INSTALL_PATH`

        if [ "x$PYTHON_PATH_STRING" == "x" ]; then

		if [ -f $PG_PYTHON_PATH/bin/python ];then
                      PYTHON_VERSION=`$PG_PYTHON_PATH/bin/python -c "import sys;t='{v[0]}.{v[1]}'.format(v=list(sys.version_info[:2]));sys.stdout.write(t)" | grep $PG_PYTHON_VERSION`
		fi

                if [ "x$PYTHON_VERSION" == "x" ]; then
                        echo "INFO --> Required Python version $PG_PYTHON_VERSION not found ..."
                else
                        echo "INFO --> Required Python version $PG_PYTHON_VERSION found at $PG_PYTHON_PATH ..."

			if [ "$1" == "1" ]; then
				PATH_PL_LANGUAGES=$PG_PYTHON_PATH/bin:$PATH_PL_LANGUAGES
				LD_LIBRARY_PATH_PL_LANGUAGES=$PG_PYTHON_PATH/lib:$LD_LIBRARY_PATH_PL_LANGUAGES
				PYTHONHOME=$PG_PYTHON_PATH
				PYTHONPATH=$PG_PYTHON_PATH
			fi
                fi
        else
                echo "WARNING --> PYTHON_INSTALL_PATH is not set in $PG_INSTALLDIR/etc/sysconfig/plLanguages.config file"
        fi
}

LoadTclPath()
{
        TCL_PATH_STRING=`cat $PG_INSTALLDIR/etc/sysconfig/plLanguages.config | grep TCL_INSTALL_PATH`

        if [ "x$TCL_PATH_STRING" == "x" ]; then

		if [ -f $PG_TCL_PATH/bin/tclsh* ];then
                        TCL_VERSION=`echo 'puts $tcl_version;exit 0' | $PG_TCL_PATH/bin/tclsh* | grep $PG_TCL_VERSION`
		fi

                if [ "x$TCL_VERSION" == "x" ]; then
                        echo "INFO --> Required Tcl version $PG_TCL_VERSION not found ..."
                else
                        echo "INFO --> Required Tcl version $PG_TCL_VERSION found at $PG_TCL_PATH ..."

			if [ "$1" == "1" ]; then
				PATH_PL_LANGUAGES=$PG_TCL_PATH/bin:$PATH_PL_LANGUAGES
				LD_LIBRARY_PATH_PL_LANGUAGES=$PG_TCL_PATH/lib:$LD_LIBRARY_PATH_PL_LANGUAGES
			fi
                fi
        else
                echo "WARNING --> TCL_INSTALL_PATH is not set in $PG_INSTALLDIR/etc/sysconfig/plLanguages.config file"
        fi
}

