
#!/bin/sh

STAGING_DIR=$1

generate_debug_symbols()
{

	os=`uname | awk '{print $1}'`

	if [ "$os" = "SunOS" ]
        then
	    OBJCOPY=/usr/sfw/bin/gobjcopy
	    STRIP=/usr/sfw/bin/gstrip
	else
	    OBJCOPY=objcopy
            STRIP=strip
	fi

	cd $STAGING_DIR
	find . -type d | xargs -I{} mkdir -p symbols/{}

	for tostripfile in `find . -type f | xargs -I{} file {} | grep ELF | grep "not stripped" | cut -d : -f 1 `; do 
    	    $OBJCOPY --only-keep-debug "${tostripfile}" "${STAGING_DIR}/symbols/${tostripfile}.symbols"
    	    $STRIP --strip-debug --strip-unneeded "${tostripfile}"
    	    $OBJCOPY --add-gnu-debuglink="${STAGING_DIR}/symbols/${tostripfile}.symbols" "${tostripfile}"
	done

	cd $WD
}

generate_debug_symbols
