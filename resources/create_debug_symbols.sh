
#!/bin/sh

STAGING_DIR=$1

generate_debug_symbols()
{

	os=`uname | awk '{print $1}'`

	if [ "$os" = "SunOS" ]
	then
		OBJCOPY=/usr/sfw/bin/gobjcopy
		STRIP=/usr/sfw/bin/gstrip
	elif [ "$os" = "Darwin" ]
	then
		OBJCOPY=/opt/local/bin/gobjcopy
		STRIP=strip
		DSYMUTIL=dsymutil
	else
		OBJCOPY=objcopy
		STRIP=strip
	fi

	cd $STAGING_DIR
	find . -type d | xargs -I{} mkdir -p debug_symbols/{}

	if [ "$os" = "Darwin" ]
	then
		#for tostripfile in `find . -type f | xargs -I{} file {} | grep "Mach-O 64-bit executable \| Mach-O 64-bit dynamically linked shared library\| Mach-O executable i386\| Mach-O 64-bit bundle \|PE32+ executable" | cut -d : -f 1 `
		for tostripfile in `find . -type f | xargs -I{} file {} | grep "Mach-O universal binary" | cut -d : -f 1 `
		do
			$DSYMUTIL "${tostripfile}" -o "${STAGING_DIR}/debug_symbols/${tostripfile}.dSYM"
			$STRIP -S "${tostripfile}"
		done
	else
		for tostripfile in `find . -type f | xargs -I{} file {} | grep ELF | grep "not stripped" | cut -d : -f 1 `
		do
			$OBJCOPY --only-keep-debug "${tostripfile}" "${STAGING_DIR}/symbols/${tostripfile}.symbols"
			$STRIP --strip-debug --strip-unneeded "${tostripfile}"
			$OBJCOPY --add-gnu-debuglink="${STAGING_DIR}/symbols/${tostripfile}.symbols" "${tostripfile}"
		done
	fi

	cd $WD
}

generate_debug_symbols
