#!/bin/sh 
# Copyright (c) 2012, EnterpriseDB Corporation.  All rights reserved
##################################################################################
# launchbrowser.sh
#
#
# Launch a url (supplied as parameter) in a web browser in a platform 
# independent manner. Since as till now(07-30-07) there are no standards 
# defined to launch a web browser in a platform independent manner, 
# therefore we implement this, more or less on the basis of guess work. 
# First we check if the $BROWSER environment variable is defined or not. If 
# its defined then we simply open the browser pointed by it, otherwise we 
# search for a list of popular browsers and invoke it as soon as we find 
# any.
###########################################################################

###########################################################################
# Global functions
###########################################################################

# usage()
# print usage
#
usage()
{
	printf "usage:\n"
	printf "$0 <url>\n"
}

###########################################################################
# Main program
###########################################################################

if [ $# -ne 1 ]
then
	usage
	exit 1
fi

URL="$1"
if [ -n "$BROWSER" ]
then
	# the browser environment variable is defined, now check if it contains
	# path to a valid web browser
	BPATH=`which $BROWSER`
	if [ $? -eq 0 ]	# the browser is valid, so invoke the command
	then
		$BPATH "$URL"
		exit 0
	fi
fi

# The $BROWSER environment variable is either not defined or does not point to a valid
# Browser. So now we have to look it up ourselves.

BRW_FOUND=0
# list of popular browsers which we are going to search 
BRW_LIST="firefox mozilla opera konqueror netscape epiphany safari"

for i in $BRW_LIST
do
	BPATH=`which $i`
	if [ $? -eq 0 ]
	then
		$BPATH "$URL"
		BRW_FOUND=1
		break
	fi
done

# exit with no success exit code (i.e 1) if browser was not found
if [ $BRW_FOUND -eq 0 ]
then
	exit 1
else
	exit 0
fi

