#!/bin/bash

# PostgreSQL server locales script (returns valid locales on the system)
# Dave Page, EnterpriseDB

#Check the command line
if [ $# -ne 0 ];
then
    echo "Usage: $0"
    exit 127
fi

# Use case-insensitive matching
shopt -s nocasematch

# OK, let's have the complete list then
_encoding_is_valid()
{
    ENCODINGS="utf8 iso88591 iso885910 iso885913 iso885914 iso885915 iso885916 iso88592 iso88593 iso88594 iso88595 iso88596 iso88597 iso88598 iso88599 abc alt euccn eucjis2004 eucjp euckr euctw koi8 koi8r latin1 latin10 latin2 latin3 latin4 latin5 latin6 latin7 latin8 latin9 muleinternal sqlascii tcvn tcvn5712 unicode vscii"

    for ENCODING in $ENCODINGS
    do
        if [[ $ENCODING =~ ^$1$ ]]
        then
            return 1
        fi
    done

    return 0
}

# Echo the locales
for LOCALE in `locale -a | grep "\."`
do
    if [[ $LOCALE =~ ([^\.]+)\.([^@]+) ]]
	then
	    ENCODING=${BASH_REMATCH[2]}
		ENCODING=${ENCODING//-/}

	    _encoding_is_valid $ENCODING
		
		if [ $? -eq 1 ];
		then
		    ENCODEDNAME=${LOCALE//-/xxDASHxx}
			ENCODEDNAME=${ENCODEDNAME//_/xxUSxx}
			ENCODEDNAME=${ENCODEDNAME//@/xxATxx}
			ENCODEDNAME=${ENCODEDNAME//./xxDOTxx}
	        echo "$ENCODEDNAME=$LOCALE"
		fi
    fi
done

