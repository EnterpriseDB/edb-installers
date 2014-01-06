
BASENAME=`basename $0`
YEAR=`date | awk '{print $NF}'`
OLD_YEAR=`expr $YEAR - 1`
WD=$PWD

    for file in `find $WD -name "*.sh" -o -name "*.bat" -o -name "*.vbs" | grep -v $BASENAME | grep -v binaries | grep -v staging | grep -v source | xargs grep "EnterpriseDB Corp"| awk '{print $1}' | cut -d":" -f1`
    do
	if ! grep $YEAR $file > /dev/null
        then
		sed "s/${OLD_YEAR}/${YEAR}/" $file > $file.tmp && mv $file.tmp $file
		chmod 755 $file
	fi
    done



