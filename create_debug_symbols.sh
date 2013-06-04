
#!/bin/sh

STAGING_DIR=$1

generate_debug_symbols()
{
	cd $STAGING_DIR
	find . -type d | xargs -I{} mkdir -p symbols/{}

	for tostripfile in `find . -type f | xargs -I{} file {} | grep ELF | grep "not stripped" | cut -d : -f 1 `; do 
    	    objcopy --only-keep-debug "${tostripfile}" "${STAGING_DIR}/symbols/${tostripfile}.symbols"
    	    strip --strip-debug --strip-unneeded "${tostripfile}"
    	    objcopy --add-gnu-debuglink="${STAGING_DIR}/symbols/${tostripfile}.symbols" "${tostripfile}"
	done

	cd $WD
}

generate_debug_symbols
