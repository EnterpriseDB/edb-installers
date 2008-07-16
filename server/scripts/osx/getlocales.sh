#!/bin/sh

# PostgreSQL server locales script for OSX (returns valid locales on the system)
# Dave Page, EnterpriseDB

#Check the command line
if [ $# -ne 0 ];
then
    echo "Usage: $0"
    exit 127
fi

# OK, let's have the complete list then
_encoding_is_valid()
{
    ENCODINGS="abc alt euccn eucjis2004 eucjp euckr euctw iso88591 iso885910 iso885913 iso885914 iso885915 iso885916 iso88592 iso88593 iso88594 iso88595 iso88596 iso88597 iso88598 iso88599 koi8 koi8r latin1 latin10 latin2 latin3 latin4 latin5 latin6 latin7 latin8 latin9 muleinternal sqlascii tcvn tcvn5712 unicode utf8 vscii"

    for ENCODING in $ENCODINGS
    do
        if [ "x$ENCODING" = "x$1" ];
        then
            return 1
        fi
    done

    return 0
}

# Echo the locales
for LOCALE in `locale -a`
do
    LCNAME=`echo $LOCALE | awk 'BEGIN {FS="."};  {print \$1}'`
    ENCNAME=`echo $LOCALE | awk 'BEGIN {FS="."};  {print \$2}'`
    ENCABBR=`echo $ENCNAME | sed -e 's/-//g' | tr "[A-Z]" "[a-z]"`
    ENCCLEAN=`echo $ENCNAME | sed -e 's/-/xxDASHxx/g'`
    LCCLEAN=`echo $LCNAME | sed -e 's/_/xxUSxx/g'`

    if [ "x$ENCNAME" = "x" ];
    then
        echo "$LCCLEAN=$LCNAME"
    else
        _encoding_is_valid $ENCABBR
        if [ $? -eq 1 ];
        then
            echo "${LCCLEAN}xxDOTxx${ENCCLEAN}=$LCNAME.$ENCNAME"
        fi
    fi
done

